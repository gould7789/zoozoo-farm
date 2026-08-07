# ユーザーモデル — 認証・権限管理
class User < ApplicationRecord
  has_secure_password

  # 作成した各種記録一覧
  # 記録を持つユーザーは物理削除を禁止する — 監査証跡（作成者情報）を保持するため
  # 削除が必要な場合は退職処理（active = false）を使う
  has_many :health_records,   foreign_key: :created_by_id, dependent: :restrict_with_error
  has_many :feeding_records,  foreign_key: :created_by_id, dependent: :restrict_with_error
  has_many :notices,          foreign_key: :created_by_id, dependent: :restrict_with_error
  has_many :sales_records,    foreign_key: :created_by_id, dependent: :restrict_with_error
  has_many :expense_records,  foreign_key: :created_by_id, dependent: :restrict_with_error

  enum :role, { admin: 0, staff: 1 }
  # 직급 enum — adminのみ使用、staffはnil固定
  enum :position, {
    junior:            0,
    associate:         1,
    assistant_manager: 2,
    manager:           3,
    deputy_manager:    4,
    general_manager:   5
  }

  # アクティブなユーザーのみを返すスコープ（退職者除外）
  scope :active, -> { where(active: true) }

  validates :email, presence: true,
                    uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true
  # パスワードは8文字以上 — フォームのプレースホルダーとko.ymlのメッセージに合わせる
  # allow_nil: 編集時にパスワード欄が空ならパスワード変更なしとして扱うため
  # （nilを渡すとpassword_digestもnilになるので、新規作成時はpresence検証が別途効く）
  validates :password, length: { minimum: 8 }, allow_nil: true
end
