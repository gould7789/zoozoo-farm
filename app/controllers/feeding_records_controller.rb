# 給餌記録のCRUDを担当するコントローラー
# 全アクションにログイン必須、編集・削除は本人記録のみ（Adminは他者記録も操作可能）
class FeedingRecordsController < ApplicationController
  before_action :set_zone
  before_action :set_animal
  before_action :set_feeding_record, only: [ :edit, :update, :destroy ]
  before_action :require_owner,      only: [ :edit, :update, :destroy ]

  def index
    # 最新の給餌日時順に表示
    @feeding_records = @animal.feeding_records.recent
  end

  def new
    # 動物に紐づいた新規給餌記録インスタンスをビルド
    @feeding_record = @animal.feeding_records.build
  end

  def create
    @feeding_record = @animal.feeding_records.build(feeding_record_params)
    # created_byは必ずログイン中のユーザーを設定
    @feeding_record.created_by = current_user
    if @feeding_record.save
      redirect_to zone_animal_feeding_records_path(@zone, @animal), notice: "먹이 기록을 저장했습니다."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @feeding_record.update(feeding_record_params)
      redirect_to zone_animal_feeding_records_path(@zone, @animal), notice: "먹이 기록을 수정했습니다."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @feeding_record.destroy
    redirect_to zone_animal_feeding_records_path(@zone, @animal), notice: "먹이 기록을 삭제했습니다."
  end

  private

    def set_zone
      @zone = Zone.find(params[:zone_id])
    end

    def set_animal
      @animal = @zone.animals.find(params[:animal_id])
    end

    def set_feeding_record
      @feeding_record = @animal.feeding_records.find(params[:id])
    end

    # 本人記録かAdminのみ編集・削除可能
    def require_owner
      unless current_user.admin? || @feeding_record.created_by_id == current_user.id
        redirect_to root_path, alert: "권한이 없습니다."
      end
    end

    # ストロングパラメータ — created_byはコントローラーで強制設定するので除外
    def feeding_record_params
      params.require(:feeding_record).permit(:fed_at, :food_type, :amount_g, :note)
    end
end
