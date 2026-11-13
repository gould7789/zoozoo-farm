# 동물 개체 모델
# 폐사·분양은 사유와 날짜를 남기는 논리 삭제, 입력 실수만 물리 삭제한다
# 생애 관련 판단은 .claude/rules/notes/animal-lifecycle.md
# 사진 관련 판단은 .claude/rules/notes/animal-photo.md
class Animal < ApplicationRecord
  # 브라우저에서 JPEG 로 바꿔 보내지만, 그 변환이 실패했을 때의 최종 방어선
  ALLOWED_PHOTO_TYPES = %w[ image/jpeg image/png image/webp ].freeze
  # 축소를 강제하는 장치가 아니라 안전망 — JS 가 들으면 수백KB 로 도착한다
  MAX_PHOTO_BYTES = 15.megabytes

  belongs_to :zone
  belongs_to :animal_category, optional: true
  has_many :health_records,  dependent: :destroy
  has_many :feeding_records, dependent: :destroy

  # 잡 워커가 없어 preprocessed: true 를 쓰지 않는다 — variant 는 처음 참조할 때 만들어진다
  has_one_attached :photo do |attachable|
    # 아바타는 원형이라 정사각형으로 자른다.
    # 브라우저에서 이미 잘랐으면 사실상 no-op 이지만, JS 가 실패해도 모양을 맞출 수 있다
    attachable.variant :thumb,  resize_to_fill: [ 320, 320 ]
    attachable.variant :detail, resize_to_limit: [ 1200, 1200 ]
  end

  # 입수 시점에 성별을 모르는 경우가 많아 기본값이 unknown
  enum :gender,      { male: 0, female: 1, unknown: 2 }

  # prefix: :cites — Active Record가 만드는 none? 메서드와 충돌하므로 접두사를 붙인다.
  # 호출은 animal.cites_none? / animal.cites_grade_i? 형태가 된다
  enum :cites_grade, { none: 0, grade_i: 1, grade_ii: 2, grade_iii: 3 }, prefix: :cites

  # prefix: :exit — transferred? 만으로는 무엇의 상태인지 읽히지 않는다.
  # 호출은 animal.exit_deceased? / animal.exit_transferred? 형태가 된다
  enum :exit_reason, { deceased: 0, transferred: 1 }, prefix: :exit

  validates :species, presence: true, length: { maximum: 100 }
  validates :name, length: { maximum: 100 }, allow_nil: true
  validates :individual_count, numericality: { only_integer: true, greater_than_or_equal_to: 1 }
  # 첨부 파일은 validates(복수)로 다룰 수 없어 validate(단수)로 커스텀 검증을 건다
  validate :photo_must_be_supported_image
  # 사인은 몰라도(갑자기 죽는 경우) 날짜는 모를 수 없다 — 모르면 발견일을 적는다.
  validates :exited_on, presence: true, if:     :exited?
  validates :exited_on, absence:  true, unless: :exited?
  # 날짜 입력은 연도 네 자리 오타가 쉽다. 2062 를 넣으면 보관 목록 맨 위에 영원히 박히고
  # 폐사보고서에도 그 날짜가 들어간다. 람다인 이유는 상수로 쓰면 클래스 로드 시각에 굳어서다
  # allow_nil — 비었을 때는 위의 presence 가 말한다. 안 붙이면 메시지가 두 번 뜬다
  validates :exited_on, comparison: { less_than_or_equal_to: ->(_) { Date.current } },
            allow_nil: true, if: :exited?
  # DB 의 CHECK 가 active 와 exit_reason 을 함께 본다. 모델에서 먼저 막지 않으면 폼에서 사유를 비우고 보냈을 때 검증 에러가 아니라 500 으로 드러난다
  validate :exit_state_must_be_consistent

  scope :active, -> { where(active: true) }
  scope :exited, -> { where.not(exit_reason: nil) }

  # 홈 화면 알림용 — 가장 최근 건강 기록이 caution 이나 danger 인 동물.
  # 서브쿼리로 개체마다 최신 1건만 고른 뒤 그 조건으로 거른다
  # ORDER BY 가 HealthRecord.recent 와 같아야 한다 — 여기와 latest_condition 과
  # 그 스코프, 셋이 「최신 1건」을 고른다. 하나만 고치면 화면마다 다른 기록이 보인다
  scope :with_alert_condition, -> {
    active
      .joins(:health_records)
      .where(
        "health_records.id = (
          SELECT id FROM health_records hr
          WHERE hr.animal_id = animals.id
          ORDER BY hr.recorded_on DESC, hr.created_at DESC
          LIMIT 1
        )"
      )
      .where.not(health_records: { condition: :normal })
      .includes(:zone, :health_records)
      .order("health_records.condition DESC, animals.species ASC")
  }

  def exited?
    exit_reason.present?
  end

  # exit_* 를 한 번에 지운다. 따로 업데이트하면 중간 상태가 CHECK 에 걸린다
  def restore!
    update!(active: true, exit_reason: nil, exited_on: nil, exit_note: nil)
  end

  # 한국식 나이 — 태어난 해를 1살로 보고 해가 바뀔 때 더한다
  def age
    return nil if birth_date.nil?
    Date.current.year - birth_date.year + 1
  end

  # 가장 최근 건강 기록의 condition. 기록이 없으면 nil.
  # loaded? 로 가르는 이유는 N+1 때문이다. 목록에서 includes 로 미리 읽어왔으면
  # 두 가지가 HealthRecord.recent 와 같은 순서여야 한다 — recorded_on 은 date 라
  # 같은 날 두 번 적으면 동률이 나고, 경로마다 다른 키로 끊으면 화면마다 다른 기록이 최신이 된다. id 는 UUID v4 라 시간순이 아니므로 쓸 수 없다
  def latest_condition
    if health_records.loaded?
      health_records.max_by { |hr| [ hr.recorded_on, hr.created_at ] }&.condition
    else
      health_records.recent.first&.condition
    end
  end

  private

    # DB 의 CHECK 는 양방향이다 — 한쪽만 보면 반대 조합이 검증을 통과해 500 이 된다
    def exit_state_must_be_consistent
      return if active? == exit_reason.blank?

      errors.add(:exit_reason, active? ? :present : :blank)
    end

    # 메시지는 ko.yml에 둔다 — errors.format이 %{message}라 문장으로 완결시켜야 한다
    def photo_must_be_supported_image
      return unless photo.attached?

      errors.add(:photo, :unsupported_type) unless ALLOWED_PHOTO_TYPES.include?(photo.blob.content_type)
      errors.add(:photo, :too_large, limit: MAX_PHOTO_BYTES / 1.megabyte) if photo.blob.byte_size > MAX_PHOTO_BYTES
    end
end
