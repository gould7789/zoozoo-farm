# ユーザーモデル — 認証・権限管理
class User < ApplicationRecord
  has_secure_password

  # 作成した各種記録一覧
  has_many :health_records,   foreign_key: :created_by_id, dependent: :nullify
  has_many :feeding_records,  foreign_key: :created_by_id, dependent: :nullify
  has_many :notices,          foreign_key: :created_by_id, dependent: :nullify
  has_many :sales_records,    foreign_key: :created_by_id, dependent: :nullify
  has_many :expense_records,  foreign_key: :created_by_id, dependent: :nullify

  enum :role, { admin: 0, staff: 1 }

  # アクティブなユーザーのみを返すスコープ（退職者除外）
  scope :active, -> { where(active: true) }

  validates :email, presence: true,
                    uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true
end
