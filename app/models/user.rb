# ユーザーモデル — 認証・権限管理を担当
class User < ApplicationRecord
  has_secure_password

  enum :role, { admin: 0, staff: 1 }

  # アクティブなユーザーのみを返すスコープ（退職者除外）
  scope :active, -> { where(active: true) }

  validates :email, presence: true,
                    uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true
end
