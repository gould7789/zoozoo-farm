# 동물 개체 모델
# 사망·방출 시 active = false 로 논리 삭제한다
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

  validates :species, presence: true, length: { maximum: 100 }
  validates :name, length: { maximum: 100 }, allow_nil: true
  validates :individual_count, numericality: { only_integer: true, greater_than_or_equal_to: 1 }
  # 첨부 파일은 validates(복수)로 다룰 수 없어 validate(단수)로 커스텀 검증을 건다
  validate :photo_must_be_supported_image

  scope :active, -> { where(active: true) }

  # 홈 화면 알림용 — 가장 최근 건강 기록이 caution 이나 danger 인 동물.
  # 서브쿼리로 개체마다 최신 1건만 고른 뒤 그 조건으로 거른다
  scope :with_alert_condition, -> {
    active
      .joins(:health_records)
      .where(
        "health_records.id = (
          SELECT id FROM health_records hr
          WHERE hr.animal_id = animals.id
          ORDER BY hr.recorded_on DESC, hr.id DESC
          LIMIT 1
        )"
      )
      .where.not(health_records: { condition: :normal })
      .includes(:zone, :health_records)
      .order("health_records.condition DESC, animals.species ASC")
  }

  # 한국식 나이 — 태어난 해를 1살로 보고 해가 바뀔 때 더한다
  def age
    return nil if birth_date.nil?
    Date.current.year - birth_date.year + 1
  end

  # 가장 최근 건강 기록의 condition. 기록이 없으면 nil.
  #
  # loaded? 로 가르는 이유는 N+1 때문이다. 목록에서 includes 로 미리 읽어왔으면
  # Ruby에서 고르고, 단건 조회처럼 안 읽어온 경우에만 쿼리를 날린다
  def latest_condition
    if health_records.loaded?
      health_records.max_by { |hr| [ hr.recorded_on, hr.id ] }&.condition
    else
      health_records.recent.first&.condition
    end
  end

  private

    # 메시지는 ko.yml에 둔다 — errors.format이 %{message}라 문장으로 완결시켜야 한다
    def photo_must_be_supported_image
      return unless photo.attached?

      errors.add(:photo, :unsupported_type) unless ALLOWED_PHOTO_TYPES.include?(photo.blob.content_type)
      errors.add(:photo, :too_large, limit: MAX_PHOTO_BYTES / 1.megabyte) if photo.blob.byte_size > MAX_PHOTO_BYTES
    end
end
