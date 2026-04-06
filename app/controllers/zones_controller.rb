# 館一覧・詳細を担当するコントローラー
# zonesはシードデータで固定 — 読み取り専用（indexとshowのみ）
class ZonesController < ApplicationController
  def index
    # 全館をid順で取得
    @zones = Zone.all.order(:id)
  end

  def show
    @zone = Zone.find(params[:id])
    # 館に所属するアクティブな動物を種名・個体名順で取得
    @animals = @zone.animals.active.order(:species, :name)
  end
end
