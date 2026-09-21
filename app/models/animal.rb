# 動物個体モデル
# 死亡・放出時はactive=falseで論理削除
class Animal < ApplicationRecord
  # プロフィール写真で許可する形式。
  # RenderのlibvipsはHEICを読めないため、到達するとvariant生成が失敗する。
  # ブラウザ側でJPEGに変換しているが、変換に失敗した場合の最終防衛線として弾く。
  ALLOWED_PHOTO_TYPES = %w[ image/jpeg image/png image/webp ].freeze
  # 縮小を強制する装置ではなく安全網。ブラウザで1600pxに縮小済みなら
  # 数百KBで届く。JSが失敗した場合にスマホの原本は通し、異常に大きいものだけ弾く。
  MAX_PHOTO_BYTES = 15.megabytes

  # 動物は必ずいずれかの館に所属する
  belongs_to :zone
  # カテゴリは任意 — 未分類の動物はNULL
  belongs_to :animal_category, optional: true
  # 健康記録
  has_many :health_records,  dependent: :destroy
  # 給餌記録
  has_many :feeding_records, dependent: :destroy

  # プロフィール写真（1枚）。
  # ジョブワーカーが無い環境のため preprocessed: true は使えない。
  # variantは初回参照時に生成され、以降は保存されたものが再利用される。
  has_one_attached :photo do |attachable|
    # アバターは円形で表示するため正方形に切り抜く。
    # ブラウザ側で切り抜き済みなら実質no-opだが、JSが失敗して
    # 元の縦横比のまま届いた場合もアバターの見た目を揃えられる。
    attachable.variant :thumb,  resize_to_fill: [ 320, 320 ]
    attachable.variant :detail, resize_to_limit: [ 1200, 1200 ]
  end

  # 性別 — 入手時に不明なケースが多いためデフォルトはunknown
  enum :gender,      { male: 0, female: 1, unknown: 2 }

  # CITES（ワシントン条約）区分 — prefix: :citesでARのnone?メソッドとの衝突を回避
  # 呼び出し方: animal.cites_none? / animal.cites_grade_i?
  enum :cites_grade, { none: 0, grade_i: 1, grade_ii: 2, grade_iii: 3 }, prefix: :cites

  # 種名は必須、個体名は多頭種のためNULL許容
  validates :species, presence: true, length: { maximum: 100 }
  validates :name, length: { maximum: 100 }, allow_nil: true
  # 個体数は1以上の整数（デフォルト1）
  validates :individual_count, numericality: { only_integer: true, greater_than_or_equal_to: 1 }
  # 添付ファイルはvalidatesで扱えないためカスタム検証で行う
  validate :photo_must_be_supported_image

  # 削除されていない動物のみを返すスコープ
  scope :active, -> { where(active: true) }

  # 最新の健康記録がcautionまたはdangerの動物を返すスコープ（ホーム画面アラート用）
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

  # 韓国式年齢計算 — 生まれた年を1歳とし、元日に加算する
  def age
    return nil if birth_date.nil?
    Date.current.year - birth_date.year + 1
  end

  # 最新の健康記録のconditionを返す — 記録がなければnilを返す
  # includesで先読み済みの場合はRubyでソートしてN+1を回避する
  def latest_condition
    if health_records.loaded?
      health_records.max_by { |hr| [ hr.recorded_on, hr.id ] }&.condition
    else
      health_records.recent.first&.condition
    end
  end

  private

    # 添付写真の形式とサイズを検証する。
    # メッセージはko.ymlに置く — errors.formatが%{message}のため文として完結させる。
    def photo_must_be_supported_image
      return unless photo.attached?

      errors.add(:photo, :unsupported_type) unless ALLOWED_PHOTO_TYPES.include?(photo.blob.content_type)
      errors.add(:photo, :too_large, limit: MAX_PHOTO_BYTES / 1.megabyte) if photo.blob.byte_size > MAX_PHOTO_BYTES
    end
end
