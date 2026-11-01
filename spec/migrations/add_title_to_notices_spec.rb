require "rails_helper"
require Rails.root.join("db/migrate/20261030020000_add_title_to_notices")

# 기존 공지에도 제목이 필요하다. 운영 DB 를 고치므로
# 무엇이 제목이 되는지를 실제 데이터로 확인한다.
RSpec.describe AddTitleToNotices do
  subject(:migration) { described_class.new }

  def create_notice(content)
    create(:notice, content: content)
  end

  def title_of(notice)
    ActiveRecord::Base.connection.select_value(
      "SELECT title FROM notices WHERE id = #{ActiveRecord::Base.connection.quote(notice.id)}"
    )
  end

  around do |example|
    was = ActiveRecord::Migration.verbose
    ActiveRecord::Migration.verbose = false
    example.run
    ActiveRecord::Migration.verbose = was
  end

  # 운영과 같은 순서로 재현한다 — 제목이 없는 공지를 만든 뒤 컬럼을 떨어뜨리고
  # 거기에 이관을 돌린다. PostgreSQL 은 DDL 도 트랜잭션에 올라가므로
  # example 이 끝나면 컬럼이 되돌아온다
  def run_migration
    ActiveRecord::Base.connection.remove_column(:notices, :title)
    Notice.reset_column_information
    migration.up
    Notice.reset_column_information
  end

  after { Notice.reset_column_information }

  describe "#up" do
    it "본문의 첫 줄을 제목으로 쓴다" do
      notice = create_notice("<div>급수대 점검<br>오전 9시부터</div>")

      run_migration

      expect(title_of(notice)).to eq("급수대 점검")
    end

    it "100자를 넘는 첫 줄은 잘라낸다" do
      notice = create_notice("<div>#{'가' * 150}</div>")

      run_migration

      expect(title_of(notice).length).to eq(100)
    end

    it "첨부만 있는 공지는 첨부 이름을 제목으로 쓴다 — 평문이 개행으로 시작한다" do
      blob = ActiveStorage::Blob.create_and_upload!(
        io: Rails.root.join("spec/fixtures/files/animal.jpg").open,
        filename: "사진.jpg", content_type: "image/jpeg"
      )
      notice = create_notice(ActionText::Content.new.append_attachables(blob))

      run_migration

      expect(title_of(notice)).to eq("[사진.jpg]")
    end

    # presence 검증이 없던 시절의 행이 운영에 남아 있을 수 있다.
    # 검증을 거치지 않고 직접 넣어 이관이 떨어지지 않는지 확인한다
    it "평문을 못 얻으면 기본 제목을 넣는다" do
      notice = create_notice("<div>지울 본문</div>")
      ActionText::RichText
        .find_by(record_type: "Notice", record_id: notice.id, name: "content")
        .update_column(:body, "<div><br></div>")

      run_migration

      expect(title_of(notice)).to eq("공지")
    end

    it "NOT NULL 을 붙인다" do
      create_notice("<div>안내</div>")

      run_migration

      Notice.reset_column_information
      expect(Notice.columns_hash["title"].null).to be false
    end
  end
end
