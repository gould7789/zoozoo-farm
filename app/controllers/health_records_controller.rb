# 健康記録のCRUDを担当するコントローラー
# 全アクションにログイン必須、編集・削除は本人記録のみ（Adminは他者記録も操作可能）
class HealthRecordsController < ApplicationController
  before_action :set_zone
  before_action :set_animal
  before_action :set_health_record, only: [ :edit, :update, :destroy ]
  before_action :require_owner,     only: [ :edit, :update, :destroy ]

  def index
    # 最新の観察日順に表示
    @health_records = @animal.health_records.recent
    respond_to do |format|
      format.html
      format.csv do
        send_data health_records_csv(@health_records),
                  filename: "건강기록_#{@animal.name.presence || @animal.species}_#{Date.today}.csv",
                  type: "text/csv; charset=utf-8",
                  disposition: "attachment"
      end
    end
  end

  def new
    # 動物に紐づいた新規健康記録インスタンスをビルド
    @health_record = @animal.health_records.build
  end

  def create
    @health_record = @animal.health_records.build(health_record_params)
    # created_byは必ずログイン中のユーザーを設定
    @health_record.created_by = current_user
    if @health_record.save
      redirect_to zone_animal_health_logs_path(@zone, @animal), notice: "건강 기록을 저장했습니다."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @health_record.update(health_record_params)
      redirect_to zone_animal_health_logs_path(@zone, @animal), notice: "건강 기록을 수정했습니다."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @health_record.destroy
    redirect_to zone_animal_health_logs_path(@zone, @animal), notice: "건강 기록을 삭제했습니다."
  end

  private

    def set_zone
      @zone = Zone.find(params[:zone_id])
    end

    def set_animal
      @animal = @zone.animals.find(params[:animal_id])
    end

    def set_health_record
      @health_record = @animal.health_records.find(params[:id])
    end

    # 本人記録かAdminのみ編集・削除可能
    def require_owner
      unless current_user.admin? || @health_record.created_by_id == current_user.id
        redirect_to root_path, alert: "권한이 없습니다."
      end
    end

    # ストロングパラメータ — created_byはコントローラーで強制設定するので除外
    def health_record_params
      params.require(:health_record).permit(:recorded_on, :weight_kg, :condition, :note)
    end

    def health_records_csv(records)
      CSV.generate(encoding: "UTF-8") do |csv|
        csv << [ "관찰일", "체중(kg)", "상태", "특이사항", "작성자", "입력일" ]
        records.each do |r|
          csv << [
            r.recorded_on,
            r.weight_kg,
            I18n.t("enums.health_record.condition.#{r.condition}"),
            r.note,
            r.created_by&.name,
            r.created_at.strftime("%Y-%m-%d %H:%M")
          ]
        end
      end
    end
end
