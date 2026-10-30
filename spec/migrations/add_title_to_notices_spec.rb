require "rails_helper"
require Rails.root.join("db/migrate/20261030020000_add_title_to_notices")

# 既存のお知らせにも題名が要る。本番DBを書き換えるので、
# 何が題名になるのかを実データで確認する。
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

  # 本番と同じ順序で再現する — 題名が無い状態のお知らせを作ってから列を落とし、
  # そこへ移行をかける。PostgreSQLはDDLもトランザクションに乗るので
  # exampleが終われば列は元に戻る
  def run_migration
    ActiveRecord::Base.connection.remove_column(:notices, :title)
    Notice.reset_column_information
    migration.up
    Notice.reset_column_information
  end

  after { Notice.reset_column_information }

  describe "#up" do
    it "本文の1行目を題名にする" do
      notice = create_notice("<div>급수대 점검<br>오전 9시부터</div>")

      run_migration

      expect(title_of(notice)).to eq("급수대 점검")
    end

    it "100文字を超える1行目は切り詰める" do
      notice = create_notice("<div>#{'가' * 150}</div>")

      run_migration

      expect(title_of(notice).length).to eq(100)
    end

    # 添付だけのお知らせは平文が改行で始まる。1行目を取ると空になる
    it "添付だけのお知らせは添付名を題名にする" do
      blob = ActiveStorage::Blob.create_and_upload!(
        io: Rails.root.join("spec/fixtures/files/animal.jpg").open,
        filename: "사진.jpg", content_type: "image/jpeg"
      )
      notice = create_notice(ActionText::Content.new.append_attachables(blob))

      run_migration

      expect(title_of(notice)).to eq("[사진.jpg]")
    end

    # presence 検証が無かった頃の行が本番に残っている可能性がある。
    # 検証を通さず直接入れて、移行が落ちないことを確かめる
    it "平文が取れなければ既定の題名を入れる" do
      notice = create_notice("<div>지울 본문</div>")
      ActionText::RichText
        .find_by(record_type: "Notice", record_id: notice.id, name: "content")
        .update_column(:body, "<div><br></div>")

      run_migration

      expect(title_of(notice)).to eq("공지")
    end

    it "NOT NULLを付ける" do
      create_notice("<div>안내</div>")

      run_migration

      Notice.reset_column_information
      expect(Notice.columns_hash["title"].null).to be false
    end
  end
end
