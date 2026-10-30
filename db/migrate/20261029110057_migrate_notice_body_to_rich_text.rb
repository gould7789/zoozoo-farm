# notices.body（平文）を Action Text のリッチテキストへ移行する。
#
# 本番DBの既存データを書き換えるため、以下の方針を取る。
#   - body カラムは残す（読み書きしない保管用）。確認後に別PRで落とす
#   - down で移行分を削除できるようにし、git revert で元の状態に戻せるようにする
#
# 平文の改行は HTML では消えるため simple_format で <p>/<br> を付ける。
# 先に html_escape するのは、simple_format のデフォルトのサニタイズが
# タグを剥がしつつ中身のテキストだけ残してしまい、原文が黙って変形するからである。
class MigrateNoticeBodyToRichText < ActiveRecord::Migration[8.1]
  def up
    helpers = ActionController::Base.helpers

    select_all("SELECT id, body FROM notices WHERE body IS NOT NULL").each do |row|
      html = helpers.simple_format(ERB::Util.html_escape(row["body"]), {}, sanitize: false)

      # 本文を埋め込むので squish を掛けない。掛けると HTML 内の改行まで潰れる
      execute <<~SQL
        INSERT INTO action_text_rich_texts
          (id, name, body, record_type, record_id, created_at, updated_at)
        VALUES
          (gen_random_uuid(), 'content', #{quote(html)}, 'Notice',
           #{quote(row['id'])}, NOW(), NOW())
        ON CONFLICT (record_type, record_id, name) DO NOTHING
      SQL
    end

    # body を書かなくなるので NOT NULL を外す。
    # これを忘れるとお知らせの新規作成が DB レベルで落ちる。
    change_column_null :notices, :body, true
  end

  def down
    # 移行後に作られたお知らせは body が NULL なので、先に平文へ戻す。
    # これをしないと NOT NULL を戻す時点で落ちて、down が使えなくなる。
    select_all(<<~SQL.squish).each do |row|
      SELECT record_id, body FROM action_text_rich_texts
      WHERE record_type = 'Notice' AND name = 'content'
    SQL
      plain = ActionText::Content.new(row["body"]).to_plain_text

      # 平文を埋め込むので squish を掛けない。掛けると改行が空白に潰れる
      execute <<~SQL
        UPDATE notices SET body = #{quote(plain)}
        WHERE id = #{quote(row['record_id'])} AND body IS NULL
      SQL
    end

    execute <<~SQL.squish
      DELETE FROM action_text_rich_texts
      WHERE record_type = 'Notice' AND name = 'content'
    SQL

    change_column_null :notices, :body, false
  end
end
