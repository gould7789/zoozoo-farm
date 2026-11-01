# 관(동물사) 모델
# 시드 데이터로 고정 관리 — Admin UI 없음 (신관 추가 시 seeds.rb에 추가)
class Zone < ApplicationRecord
  # restrict_with_error — 자식이 남아 있으면 destroy를 막고 errors에 담는다.
  # 예외를 던지는 restrict_with_exception과 달리 화면에 메시지로 보여줄 수 있다.
  # 논리 삭제 설계라 관을 물리 삭제할 일은 없지만 실수를 막는다
  has_many :animals, dependent: :restrict_with_error
  # 관은 시드라 사실상 삭제되지 않지만, 삭제된다면 카테고리가 고아로 남으므로 같이 지운다
  has_many :animal_categories, dependent: :destroy

  validates :name, presence: true, uniqueness: true, length: { maximum: 100 }
end
