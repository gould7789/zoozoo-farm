# users 에 직급·팀장 여부·입사일·계약 종료일을 더한다
class AddPositionAndDatesToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :position,         :integer, limit: 2
    add_column :users, :is_team_leader,   :boolean, null: false, default: false
    add_column :users, :hired_on,         :date
    add_column :users, :contract_ends_on, :date
  end
end
