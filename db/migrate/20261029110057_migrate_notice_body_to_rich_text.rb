# notices.body(평문)를 Action Text 의 리치텍스트로 이관한다.
#
# 운영 DB 의 기존 데이터를 고치므로 두 가지 방침을 둔다.
#   - body 컬럼은 남긴다 (읽지도 쓰지도 않는 보관용). 확인 뒤 별도 PR 로 떨어뜨린다
#   - down 으로 이관분을 지울 수 있게 해 git revert 로 되돌아갈 수 있게 한다
#
# 함정 4개(simple_format 의 기본 살균, NOT NULL, squish, 제목 백필)는
# .claude/rules/notes/notice.md 에 정리돼 있다.
class MigrateNoticeBodyToRichText < ActiveRecord::Migration[8.1]
  def up
    helpers = ActionController::Base.helpers

    select_all("SELECT id, body FROM notices WHERE body IS NOT NULL").each do |row|
      html = helpers.simple_format(ERB::Util.html_escape(row["body"]), {}, sanitize: false)

      # 본문을 끼워 넣으므로 squish 를 걸지 않는다 — 걸면 HTML 안의 개행까지 뭉개진다
      execute <<~SQL
        INSERT INTO action_text_rich_texts
          (id, name, body, record_type, record_id, created_at, updated_at)
        VALUES
          (gen_random_uuid(), 'content', #{quote(html)}, 'Notice',
           #{quote(row['id'])}, NOW(), NOW())
        ON CONFLICT (record_type, record_id, name) DO NOTHING
      SQL
    end

    # body 를 쓰지 않게 되므로 NOT NULL 을 뗀다.
    # 빠뜨리면 공지 신규 작성이 DB 레벨에서 떨어진다.
    change_column_null :notices, :body, true
  end

  def down
    # 이관 뒤에 만들어진 공지는 body 가 NULL 이므로 먼저 평문으로 되돌린다.
    # 안 하면 NOT NULL 을 되돌리는 시점에 떨어져 down 을 쓸 수 없다.
    select_all(<<~SQL.squish).each do |row|
      SELECT record_id, body FROM action_text_rich_texts
      WHERE record_type = 'Notice' AND name = 'content'
    SQL
      plain = ActionText::Content.new(row["body"]).to_plain_text

      # 평문을 끼워 넣으므로 squish 를 걸지 않는다 — 걸면 개행이 공백으로 뭉개진다
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
