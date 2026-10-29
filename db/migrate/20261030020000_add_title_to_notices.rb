# お知らせに題名を追加する。
#
# 一覧で本文を読まずに内容を見分けられるようにするのが目的。
# 既存の行にも値が要るので、本文の1行目から埋めてから NOT NULL を付ける。
#
# 本文はこの時点ですでにリッチテキストなので、HTMLから平文を取り出す。
# 1行目ではなく最初の空でない行を使う。添付だけのお知らせは平文が改行で始まり、
# 1行目を取ると空になってしまうためである。
# それでも取れなければ既定値を入れる。空文字のまま NOT NULL を付けると、
# presence 検証を通らない行がDBに残る。
class AddTitleToNotices < ActiveRecord::Migration[8.1]
  DEFAULT_TITLE = "공지".freeze
  MAX_LENGTH = 100

  def up
    add_column :notices, :title, :string, limit: MAX_LENGTH

    select_all(<<~SQL.squish).each do |row|
      SELECT record_id, body FROM action_text_rich_texts
      WHERE record_type = 'Notice' AND name = 'content'
    SQL
      plain = ActionText::Content.new(row["body"]).to_plain_text
      title = plain.lines.map(&:strip).find(&:present?) || DEFAULT_TITLE

      execute <<~SQL.squish
        UPDATE notices SET title = #{quote(title.first(MAX_LENGTH))}
        WHERE id = #{quote(row['record_id'])} AND title IS NULL
      SQL
    end

    # リッチテキストが無いお知らせ（移行前に本文が空だった行）も埋める
    execute <<~SQL.squish
      UPDATE notices SET title = #{quote(DEFAULT_TITLE)} WHERE title IS NULL
    SQL

    change_column_null :notices, :title, false
  end

  def down
    remove_column :notices, :title
  end
end
