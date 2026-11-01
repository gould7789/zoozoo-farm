require "rails_helper"
require Rails.root.join("db/migrate/20261029110057_migrate_notice_body_to_rich_text")

# 운영 DB 의 데이터를 고치는 마이그레이션이라
# 「평문의 개행이 HTML 로 바뀔 때 사라지지 않는가」를 실제 데이터로 확인한다.
RSpec.describe MigrateNoticeBodyToRichText do
  subject(:migration) { described_class.new }

  # 이관 전 상태를 만든다 — content 없이 body 만 있는 행을 직접 넣는다
  def insert_plain_notice(body)
    user = create(:user)
    id   = SecureRandom.uuid

    # squish 를 걸면 본문의 개행까지 뭉개져 검증 대상 자체가 깨진다
    ActiveRecord::Base.connection.execute(<<~SQL)
      INSERT INTO notices (id, created_by_id, category, title, body, created_at, updated_at)
      VALUES ('#{id}', '#{user.id}', 0, '테스트 제목',
              #{ActiveRecord::Base.connection.quote(body)}, NOW(), NOW())
    SQL

    id
  end

  def rich_text_for(notice_id)
    ActionText::RichText.find_by(record_type: "Notice", record_id: notice_id, name: "content")
  end

  around do |example|
    # 마이그레이션 로그에 테스트 출력이 묻히는 것을 막는다
    was = ActiveRecord::Migration.verbose
    ActiveRecord::Migration.verbose = false
    example.run
    ActiveRecord::Migration.verbose = was
  end

  before do
    # 이 테스트는 NOT NULL 이 붙은 이관 전 상태에서 시작한다
    ActiveRecord::Base.connection.change_column_null(:notices, :body, false)
  end

  describe "#up" do
    it "개행을 <br> 로, 빈 행을 문단 구분으로 바꾼다" do
      id = insert_plain_notice("1행\n2행\n\n새 문단")

      migration.up

      html = rich_text_for(id).body.to_s
      expect(html).to include("<br")
      expect(html.scan("<p>").size).to eq(2)
    end

    it "평문의 태그 기호를 벗기지 않고 그대로 남긴다" do
      # simple_format 의 기본 살균은 태그를 지우고 안의 텍스트만 남겨 원문을
      # 조용히 바꾼다. html_escape 를 먼저 거는 근거다.
      id = insert_plain_notice("<b>강조</b> 표기")

      migration.up

      expect(rich_text_for(id).body.to_s).to include("&lt;b&gt;강조&lt;/b&gt;")
    end

    it "이관 뒤에도 body 컬럼의 원문은 그대로 남는다" do
      id = insert_plain_notice("원본 평문")

      migration.up

      expect(Notice.find(id).body).to eq("원본 평문")
    end

    it "body 의 NOT NULL 을 뗀다" do
      migration.up

      expect { create(:notice, content: "새 공지") }.not_to raise_error
    end

    it "두 번 실행해도 중복되지 않는다" do
      id = insert_plain_notice("멱등성 확인")

      migration.up
      migration.up

      expect(ActionText::RichText.where(record_type: "Notice", record_id: id).count).to eq(1)
    end
  end

  describe "#down" do
    it "이관분을 지우고 NOT NULL 을 되돌린다" do
      id = insert_plain_notice("되돌리기 확인")
      migration.up

      migration.down

      expect(rich_text_for(id)).to be_nil
      expect(Notice.find(id).body).to eq("되돌리기 확인")
    end

    it "이관 뒤에 만들어진 행은 평문으로 되돌린다" do
      migration.up
      created_after = Notice.create!(created_by: create(:user), title: "나중 공지", content: "나중에 쓴 공지")

      migration.down

      expect(created_after.reload.body).to eq("나중에 쓴 공지")
    end
  end
end
