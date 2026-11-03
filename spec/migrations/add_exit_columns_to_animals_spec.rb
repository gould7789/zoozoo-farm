require "rails_helper"
require Rails.root.join("db/migrate/20261103000001_add_exit_columns_to_animals")

# 이 브랜치를 판 시점의 운영 DB 는 active = false 가 0 건이었지만, 배포까지의 사이에
# 누가 동물을 삭제하면 행이 생긴다. render.yaml 의 buildCommand 가 db:migrate 를
# 돌리므로 여기서 떨어지면 배포 자체가 멈춘다 — 메우기가 실제로 도는지 확인한다
RSpec.describe AddExitColumnsToAnimals do
  subject(:migration) { described_class.new }

  around do |example|
    was = ActiveRecord::Migration.verbose
    ActiveRecord::Migration.verbose = false
    example.run
    ActiveRecord::Migration.verbose = was
  end

  after { Animal.reset_column_information }

  # 운영과 같은 순서로 재현한다 — 컬럼과 제약을 떨어뜨리고, 사유 없이 비활성인 행을
  # 만든 뒤 거기에 마이그레이션을 돌린다.
  # PostgreSQL 은 DDL 도 트랜잭션에 올라가므로 example 이 끝나면 되돌아온다
  def run_migration_over(updated_at_utc:)
    connection = ActiveRecord::Base.connection
    animal = create(:animal)

    migration.down
    Animal.reset_column_information

    connection.execute(<<~SQL)
      UPDATE animals
      SET active = false, updated_at = TIMESTAMP '#{updated_at_utc}'
      WHERE id = #{connection.quote(animal.id)}
    SQL

    migration.up
    Animal.reset_column_information
    animal.id
  end

  def row(id)
    ActiveRecord::Base.connection.select_one(
      "SELECT exit_reason, exited_on, exit_note FROM animals " \
      "WHERE id = #{ActiveRecord::Base.connection.quote(id)}"
    )
  end

  describe "#up" do
    it "사유 없이 비활성인 행을 폐사로 메워 제약을 통과시킨다" do
      id = run_migration_over(updated_at_utc: "2026-03-14 05:00:00")

      expect(row(id)["exit_reason"]).to eq(0)
      expect(row(id)["exit_note"]).to be_present
    end

    # updated_at 은 UTC 다. 그냥 ::date 하면 KST 00~09 시의 삭제가 하루 앞으로 간다
    it "KST 새벽에 삭제된 행의 날짜가 하루 앞으로 가지 않는다" do
      id = run_migration_over(updated_at_utc: "2026-03-13 17:00:00")  # KST 03-14 02:00

      expect(row(id)["exited_on"].to_s).to eq("2026-03-14")
    end

    it "메운 뒤라 CHECK 가 걸리지 않는다" do
      expect { run_migration_over(updated_at_utc: "2026-03-14 05:00:00") }.not_to raise_error
    end
  end
end
