# 動物個体モデル
# 1個体 = 1レコード（多頭飼育種はnameをNULLにして種単位で管理）
# 死亡・放出時はactive=falseで論理削除（履歴保持のため物理削除しない）
class Animal < ApplicationRecord
  # 動物は必ずいずれかの館に所属する（識別関係）
  belongs_to :zone

  # 性別 — 入手時に不明なケースが多いためデフォルトはunknown(2)
  enum :gender,      { male: 0, female: 1, unknown: 2 }

  # CITES（ワシントン条約）区分 — prefix: :citesでARのnone?メソッドとの衝突を回避
  # 呼び出し方: animal.cites_none? / animal.cites_grade_i?
  enum :cites_grade, { none: 0, grade_i: 1, grade_ii: 2, grade_iii: 3 }, prefix: :cites

  # 種名は必須、個体名は多頭種のためNULL許容
  validates :species, presence: true, length: { maximum: 100 }
  validates :name, length: { maximum: 100 }, allow_nil: true

  # 論理削除されていない（現役の）動物のみを返すスコープ
  scope :active, -> { where(active: true) }
end
