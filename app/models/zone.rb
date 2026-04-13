# ゾーン（動物舎）モデル
# シードデータで固定管理 — Admin UIなし（新館追加時はseeds.rbに追記）
# 動物が紐づいている館は削除できない（restrict_with_error）
class Zone < ApplicationRecord
  # 1つの館に複数の動物が所属する
  # 動物が存在する館はdestroyを禁止（論理削除設計のため物理削除は想定しない）
  has_many :animals, dependent: :restrict_with_error

  # 館名は必須・一意・100文字以内
  validates :name, presence: true, uniqueness: true, length: { maximum: 100 }
end
