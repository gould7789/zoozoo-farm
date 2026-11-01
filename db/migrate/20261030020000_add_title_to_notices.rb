# 공지에 제목을 더한다. 목록에서 본문을 읽지 않고 내용을 가르기 위해서다.
#
# 기존 행에도 값이 필요하므로 본문에서 채운 뒤 NOT NULL 을 붙인다.
# 첫 줄이 아니라 「첫 비어있지 않은 줄」을 쓰는 이유와 기본값을 두는 이유는
# .claude/rules/notes/notice.md
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

    # 리치텍스트가 없는 공지(이관 전에 본문이 비었던 행)도 채운다
    execute <<~SQL.squish
      UPDATE notices SET title = #{quote(DEFAULT_TITLE)} WHERE title IS NULL
    SQL

    change_column_null :notices, :title, false
  end

  def down
    remove_column :notices, :title
  end
end
