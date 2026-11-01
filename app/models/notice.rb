# 공지 모델 — 전체 및 각 관 대상 통지
# 설계 배경은 .claude/rules/notes/notice.md
class Notice < ApplicationRecord
  # Render의 libvips가 HEIC를 읽지 못해 variant 생성이 실패한다 (Animal 사진과 같은 이유)
  ALLOWED_EMBED_TYPES = %w[ image/jpeg image/png image/webp ].freeze
  # 브라우저에서 1600px로 줄이므로 보통 수백KB로 도착한다. JS가 실패했을 때의 안전망
  MAX_EMBED_BYTES = 15.megabytes

  belongs_to :created_by, class_name: "User"

  # :body 가 아니라 :content — has_rich_text 는 class_eval 로 모델 클래스에 직접
  # 접근자를 정의하므로, :body 로 두면 기존 body 컬럼이 가려진다
  has_rich_text :content

  enum :category, {
    general:      0,
    lovebird:     1,
    parrot:       2,
    reptile:      3,
    small_animal: 4,
    outdoor:      5,
    isolation:    6
  }

  validates :title,    presence: true, length: { maximum: 100 }
  validates :content,  presence: true
  validates :category, presence: true
  # 임베드 이미지는 다이렉트 업로드로 들어와 폼 검증을 통과하지 않는다.
  # 첨부는 validates(복수)로 다룰 수 없어 커스텀 검증으로 건다
  validate :embeds_must_be_supported_images

  scope :recent, -> { order(created_at: :desc) }

  # 목록에 내보낼 발췌.
  #   to_plain_text 를 안 쓰는 이유    첨부를 1건씩 sgid 로 다시 읽어 N+1 이 된다
  #   태그를 공백으로 치환하는 이유     strip_tags 는 블록 경계에 공백을 넣지 않는다
  #   Nokogiri 의 text 를 거치는 이유   &lt; 같은 실체 참조를 되돌린다 (&nbsp; 포함)
  def excerpt(length: 80)
    spaced = content.body.to_html.gsub(/<[^>]*>/, " ")
    Nokogiri::HTML5.fragment(spaced).text.squish.truncate(length)
  end

  # 본문에 붙은 사진 수. 0이면 목록에 배지를 띄우지 않는다.
  # body.attachables 가 아니라 embeds — 전자는 sgid 를 1건씩 GlobalID 로 다시 읽는다
  def photo_count
    content.embeds.size
  end

  private

    # content.embeds 는 리치텍스트 저장 시점에 채워져 검증 시점에는 비어 있다.
    # 그래서 본문 HTML 에서 attachable 을 직접 꺼낸다
    def embeds_must_be_supported_images
      return if content.blank?

      attachables = content.body.attachables

      # 에디터가 만드는 첨부는 반드시 ActiveStorage::Blob 이다.
      # 손으로 조립한 <action-text-attachment url="..."> 는 RemoteImage 가 되어
      # 아래 blob 검증을 지나치고 <img src="외부URL"> 로 그려진다.
      # CSP 의 img-src 가 막아 지금은 실해가 없지만, 방어를 한 겹에 맡기지 않는다
      unless attachables.all? { |attachable| attachable.is_a?(ActiveStorage::Blob) }
        errors.add(:content, :unsupported_attachment)
        return
      end

      attachables.each do |blob|
        # content_type 은 브라우저의 신고값이 아니라 실체에서 판정된 값이다.
        # ActiveStorage::Attached::Changes 가 첨부를 조립할 때 identify_without_saving
        # 을 거치므로 여기 오기 전에 확정된다. Rails 내부 동작이라 위장 파일 spec 으로 고정해뒀다
        errors.add(:content, :unsupported_type) unless ALLOWED_EMBED_TYPES.include?(blob.content_type)
        errors.add(:content, :too_large, limit: MAX_EMBED_BYTES / 1.megabyte) if blob.byte_size > MAX_EMBED_BYTES
      end
    end
end
