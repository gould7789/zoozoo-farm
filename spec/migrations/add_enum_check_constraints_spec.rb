require "rails_helper"
require Rails.root.join("db/migrate/20261102000001_add_enum_check_constraints")

# 운영 DB 에 제약을 거는 마이그레이션이라 양방향을 확인한다.
# down 이 동작하지 않으면 되돌릴 수단이 없다.
RSpec.describe AddEnumCheckConstraints do
  subject(:migration) { described_class.new }

  def connection = ActiveRecord::Base.connection

  def constraint_names(table)
    connection.check_constraints(table).map(&:name)
  end

  def column_limit(table, column)
    connection.columns(table).find { |c| c.name == column.to_s }.limit
  end

  around do |example|
    was = ActiveRecord::Migration.verbose
    ActiveRecord::Migration.verbose = false
    example.run
    ActiveRecord::Migration.verbose = was
  end

  # 스키마에는 이미 적용돼 있으므로, down 으로 되돌린 뒤 up 을 검증한다.
  # PostgreSQL 은 DDL 도 트랜잭션에 올라가 example 이 끝나면 복구된다
  after { [ Animal, User, Notice, ExpenseRecord, SalesRecord, HealthRecord ].each(&:reset_column_information) }

  describe "#up" do
    before { migration.down }

    it "CHECK 제약 7건을 건다" do
      expect {
        migration.up
      }.to change { described_class::CONSTRAINTS.count { |t, _e, n| constraint_names(t).include?(n) } }.from(0).to(7)
    end

    it "4개 컬럼을 smallint 로 좁힌다" do
      described_class::NARROW.each { |table, column| expect(column_limit(table, column)).to eq(4) }
      migration.up
      described_class::NARROW.each { |table, column| expect(column_limit(table, column)).to eq(2) }
    end

    it "제약이 실제로 범위 밖 값을 막는다" do
      migration.up
      Animal.reset_column_information
      animal = create(:animal)

      expect { animal.update_column(:gender, 9) }
        .to raise_error(ActiveRecord::StatementInvalid, /chk_animals_gender/)
    end

    # Staff 는 직급이 없다. IS NULL OR 를 빠뜨리면 계정 생성이 DB 에서 떨어진다
    it "users.position 의 NULL 은 막지 않는다" do
      migration.up
      User.reset_column_information

      expect { create(:user, position: nil) }.not_to raise_error
    end
  end

  describe "#down" do
    it "CHECK 제약 7건을 뗀다" do
      expect {
        migration.down
      }.to change { described_class::CONSTRAINTS.count { |t, _e, n| constraint_names(t).include?(n) } }.from(7).to(0)
    end

    it "컬럼 폭을 되돌린다" do
      migration.down
      described_class::NARROW.each { |table, column| expect(column_limit(table, column)).to eq(4) }
    end

    # down 뒤에는 범위 밖 값이 다시 들어간다 — 제약이 정말 떨어졌다는 뜻이다
    it "되돌리면 범위 밖 값이 통과한다" do
      animal = create(:animal)
      migration.down
      Animal.reset_column_information

      expect { animal.update_column(:gender, 9) }.not_to raise_error
    end
  end

  # 기존에 유일하게 있던 CHECK 는 이 마이그레이션이 건드리지 않는다
  it "chk_health_condition 은 그대로 남는다" do
    migration.down
    expect(constraint_names(:health_records)).to include("chk_health_condition")
  end
end
