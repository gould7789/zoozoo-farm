# ユーザーテーブルを作成するマイグレーション
class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    enable_extension "pgcrypto" unless extension_enabled?("pgcrypto")

    create_table :users, id: :uuid do |t|
      t.string  :email,           null: false, limit: 255
      t.string  :password_digest, null: false
      t.string  :name,            null: false, limit: 100
      t.integer :role,            null: false, default: 1, limit: 2
      t.boolean :active,          null: false, default: true

      t.timestamps
    end

    add_index :users, :email, unique: true
  end
end
