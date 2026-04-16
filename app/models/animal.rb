# 動物個体モデル
# 死亡・放出時はactive=falseで論理削除
class Animal < ApplicationRecord
  # 動物は必ずいずれかの館に所属する
  belongs_to :zone
  # カテゴリは任意 — 未分類の動物はNULL
  belongs_to :animal_category, optional: true
  # 健康記録
  has_many :health_records,  dependent: :destroy
  # 給餌記録
  has_many :feeding_records, dependent: :destroy

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

  # 削除されていない動物のみを返すスコープ
  scope :active, -> { where(active: true) }
end
