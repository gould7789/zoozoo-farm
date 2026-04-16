# Zoneモデルのバリデーション・アソシエーションをテストする
require "rails_helper"

RSpec.describe Zone, type: :model do
  # uniquenessテスト用にアルファ文字を含む有効なsubjectを用意する
  subject { Zone.new(name: "Zone A") }

  describe "バリデーション" do
    # 館名は必須
    it { should validate_presence_of(:name) }
    # 館名は一意（重複不可）
    it { should validate_uniqueness_of(:name) }
    # 館名は100文字以内
    it { should validate_length_of(:name).is_at_most(100) }
  end

  describe "アソシエーション" do
    # 動物が紐づいている館は削除できない（論理削除のみ許容する設計のため）
    it { should have_many(:animals).dependent(:restrict_with_error) }
    # 館削除時はカテゴリも削除
    it { should have_many(:animal_categories).dependent(:destroy) }
  end
end
