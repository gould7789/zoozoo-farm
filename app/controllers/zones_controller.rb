# 館一覧・詳細を担当するコントローラー
# zonesはシードデータで固定 — 読み取り専用（indexとshowのみ）
class ZonesController < ApplicationController
  def index
    # 表示順を固定 — シードデータの並び順に合わせて名前でソート
    display_order = [ "사랑새관", "앵무새관", "파충류관", "미니동물관", "야외동물체험관", "격리실" ]
    @zones = Zone.all.sort_by { |z| display_order.index(z.name) || 999 }
    # 各館のアクティブ動物のindividual_count合計を一括取得（N+1防止）
    @zone_counts = Animal.active.group(:zone_id).sum(:individual_count)
  end

  def show
    @zone = Zone.find(params[:id])
    # アコーディオン表示用: hiddenでないカテゴリのみ
    @categories = @zone.animal_categories.where(hidden: false).order(:name)
    # モーダル用: 全カテゴリ（チェックボックス表示のため hidden含む）
    @all_categories = @zone.animal_categories.order(:name)
    # アクティブ動物を一括ロードしてカテゴリIDでグループ化（N+1防止）
    # @animals_by_category[category.id] → そのカテゴリの動物
    # @animals_by_category[nil]         → 未分類の動物
    @animals_by_category = @zone.animals.active
                                .includes(:health_records)
                                .order(:species, :name)
                                .group_by(&:animal_category_id)
  end
end
