# 폐사·분양을 사유와 날짜로 남긴다. 판단 근거는 .claude/rules/notes/animal-lifecycle.md
class AddExitColumnsToAnimals < ActiveRecord::Migration[8.1]
  def up
    add_column :animals, :exit_reason, :integer, limit: 2
    add_column :animals, :exited_on,   :date
    add_column :animals, :exit_note,   :text

    # 이 브랜치를 판 시점의 운영 DB 는 active = false 가 0 건이었지만, 배포까지의 사이에
    # 누가 동물을 삭제하면 행이 생긴다. render.yaml 의 buildCommand 가 db:migrate 를
    # 돌리므로 여기서 떨어지면 배포 자체가 멈춘다 — 그래서 먼저 메운다.
    # 사유를 폐사로 보는 이유는 분양이 드물기 때문이고, 날짜는 삭제 조작 시각을 쓴다.
    # updated_at 은 UTC 라 그냥 ::date 하면 KST 00~09 시의 삭제가 하루 앞으로 간다
    execute <<~SQL
      UPDATE animals
      SET exit_reason = 0,
          exited_on = (updated_at AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Seoul')::date,
          exit_note = '이 기능이 생기기 전에 삭제된 개체입니다'
      WHERE active = false
    SQL

    # 「나갔는데 목록에 보이는 행」과 「사라졌는데 이유를 모르는 행」을 둘 다 막는다.
    # active 를 파생값으로 지우지 않고 남긴 이유는 목록 필터가 쓰는 빠른 칸이어서다
    add_check_constraint :animals, "(active = false) = (exit_reason IS NOT NULL)",
                         name: "chk_animals_exit_consistency"

    # 사인은 몰라도 날짜는 모를 수 없다 — 모르면 발견일을 적는다
    add_check_constraint :animals, "(exit_reason IS NULL) = (exited_on IS NULL)",
                         name: "chk_animals_exit_date"

    add_check_constraint :animals, "exit_reason IN (0,1)", name: "chk_animals_exit_reason"
  end

  def down
    remove_check_constraint :animals, name: "chk_animals_exit_reason"
    remove_check_constraint :animals, name: "chk_animals_exit_date"
    remove_check_constraint :animals, name: "chk_animals_exit_consistency"

    remove_column :animals, :exit_note
    remove_column :animals, :exited_on
    remove_column :animals, :exit_reason
  end
end
