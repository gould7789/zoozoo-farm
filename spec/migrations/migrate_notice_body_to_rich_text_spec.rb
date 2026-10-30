require "rails_helper"
require Rails.root.join("db/migrate/20261029110057_migrate_notice_body_to_rich_text")

# 本番DBのデータを書き換えるマイグレーションなので、
# 「平文の改行が HTML で消えないか」を実データで確認する。
RSpec.describe MigrateNoticeBodyToRichText do
  subject(:migration) { described_class.new }

  # 移行前の状態を作る — content を付けずに body だけの行を直接入れる
  def insert_plain_notice(body)
    user = create(:user)
    id   = SecureRandom.uuid

    # squish を掛けると本文の改行まで潰れ、検証対象そのものが壊れる
    ActiveRecord::Base.connection.execute(<<~SQL)
      INSERT INTO notices (id, created_by_id, category, title, body, created_at, updated_at)
      VALUES ('#{id}', '#{user.id}', 0, 'テスト題名',
              #{ActiveRecord::Base.connection.quote(body)}, NOW(), NOW())
    SQL

    id
  end

  def rich_text_for(notice_id)
    ActionText::RichText.find_by(record_type: "Notice", record_id: notice_id, name: "content")
  end

  around do |example|
    # マイグレーションのログでテスト出力が埋もれるのを防ぐ
    was = ActiveRecord::Migration.verbose
    ActiveRecord::Migration.verbose = false
    example.run
    ActiveRecord::Migration.verbose = was
  end

  before do
    # このテストは NOT NULL が付いた移行前の状態から始める
    ActiveRecord::Base.connection.change_column_null(:notices, :body, false)
  end

  describe "#up" do
    it "改行を<br>に、空行を段落の区切りに変換する" do
      id = insert_plain_notice("1행\n2행\n\n새 문단")

      migration.up

      html = rich_text_for(id).body.to_s
      expect(html).to include("<br")
      expect(html.scan("<p>").size).to eq(2)
    end

    it "平文のタグ記号を剥がさずそのまま残す" do
      # simple_format のデフォルトサニタイズはタグを消して中身だけ残すため、
      # 原文が黙って変わる。html_escape を先にかけている根拠。
      id = insert_plain_notice("<b>강조</b> 표기")

      migration.up

      expect(rich_text_for(id).body.to_s).to include("&lt;b&gt;강조&lt;/b&gt;")
    end

    it "移行後も body カラムの原文はそのまま残る" do
      id = insert_plain_notice("원본 평문")

      migration.up

      expect(Notice.find(id).body).to eq("원본 평문")
    end

    it "body の NOT NULL を外す" do
      migration.up

      expect { create(:notice, content: "새 공지") }.not_to raise_error
    end

    it "二度実行しても重複しない" do
      id = insert_plain_notice("멱등성 확인")

      migration.up
      migration.up

      expect(ActionText::RichText.where(record_type: "Notice", record_id: id).count).to eq(1)
    end
  end

  describe "#down" do
    it "移行分を消して NOT NULL を戻す" do
      id = insert_plain_notice("되돌리기 확인")
      migration.up

      migration.down

      expect(rich_text_for(id)).to be_nil
      expect(Notice.find(id).body).to eq("되돌리기 확인")
    end

    it "移行後に作られた行は平文へ書き戻す" do
      migration.up
      created_after = Notice.create!(created_by: create(:user), title: "나중 공지", content: "나중에 쓴 공지")

      migration.down

      expect(created_after.reload.body).to eq("나중에 쓴 공지")
    end
  end
end
