# お知らせモデル — 全体および各館向けの通知を管理する
class Notice < ApplicationRecord
  # 作成者
  belongs_to :created_by, class_name: "User"

  # カテゴリ enum（0=全体, 1=コザクラ館, 2=オウム館, 3=爬虫類館, 4=ミニ動物館, 5=屋外体験館, 6=隔離室）
  enum :category, {
    general:      0,
    lovebird:     1,
    parrot:       2,
    reptile:      3,
    small_animal: 4,
    outdoor:      5,
    isolation:    6
  }

  # 本文・カテゴリは必須
  validates :body,     presence: true
  validates :category, presence: true

  # 最新投稿順に並べるスコープ
  scope :recent, -> { order(created_at: :desc) }
end
