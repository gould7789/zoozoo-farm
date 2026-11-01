# notices 테이블
class CreateNotices < ActiveRecord::Migration[8.0]
  def change
    create_table :notices, id: :uuid do |t|
      t.references :created_by, null: false, foreign_key: { to_table: :users }, type: :uuid
      # 0=전체, 1=사랑새관, 2=앵무새관, 3=파충류관, 4=미니동물관, 5=야외동물체험관, 6=격리실
      t.integer :category, null: false, default: 0
      t.text :body, null: false

      t.timestamps
    end

    add_index :notices, :category
  end
end
