# 館一覧・詳細を担当するコントローラー
# zonesはシードデータで固定 — 読み取り専用（indexとshowのみ）
class ZonesController < ApplicationController
  def index
    # 表示順を固定 — シードデータの並び順に合わせて名前でソート
    display_order = [ "사랑새관", "앵무새관", "파충류관", "미니동물관", "야외동물체험관", "격리실" ]
    @zones = Zone.all.sort_by { |z| display_order.index(z.name) || 999 }
  end

  def show
    @zone = Zone.find(params[:id])
    # 館に所属するアクティブな動物を種名・個体名順で取得 — N+1防止のため健康記録を一括ロード
    @animals = @zone.animals.active.includes(:health_records).order(:species, :name)
  end
end
