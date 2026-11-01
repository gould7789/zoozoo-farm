# 사용자 모델 — 인증과 권한
# 판단 근거는 .claude/rules/notes/auth.md
class User < ApplicationRecord
  has_secure_password

  # 기록을 가진 사용자는 물리 삭제를 막는다 — 감사 추적(작성자 정보)을 보존해야 한다.
  # 지워야 하면 퇴사 처리(active = false)를 쓴다
  has_many :health_records,   foreign_key: :created_by_id, dependent: :restrict_with_error
  has_many :feeding_records,  foreign_key: :created_by_id, dependent: :restrict_with_error
  has_many :notices,          foreign_key: :created_by_id, dependent: :restrict_with_error
  has_many :sales_records,    foreign_key: :created_by_id, dependent: :restrict_with_error
  has_many :expense_records,  foreign_key: :created_by_id, dependent: :restrict_with_error

  enum :role, { admin: 0, staff: 1 }
  # 직급 — admin만 쓰고 staff는 nil로 둔다
  enum :position, {
    junior:            0,
    associate:         1,
    assistant_manager: 2,
    manager:           3,
    deputy_manager:    4,
    general_manager:   5
  }

  scope :active, -> { where(active: true) }

  validates :email, presence: true,
                    uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true
  # allow_nil — 수정 화면에서 비밀번호 칸을 비우면 "변경 안 함"으로 다루기 위해서다.
  # nil을 넘기면 password_digest도 nil이 되지만, 신규 생성 시에는
  # has_secure_password가 거는 presence 검증이 따로 잡아준다
  validates :password, length: { minimum: 8 }, allow_nil: true
end
