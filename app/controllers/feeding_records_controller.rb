# 給餌記録のCRUDを担当するコントローラー
# 全アクションにログイン必須、編集・削除は本人記録のみ（Adminは他者記録も操作可能）
class FeedingRecordsController < ApplicationController
  include AnimalScoped
  include OwnerRestriction

  before_action :set_feeding_record,                    only: [ :edit, :update, :destroy ]
  before_action -> { require_owner(@feeding_record) },  only: [ :edit, :update, :destroy ]

  def index
    # 最新の給餌日時順に表示
    @feeding_records = @animal.feeding_records.recent.includes(:created_by)
    respond_to do |format|
      format.html
      format.xlsx do
        return redirect_to root_path, alert: "권한이 없습니다." unless current_user.admin?
        send_data feeding_records_xlsx(@feeding_records),
                  filename: "먹이기록_#{@animal.name.presence || @animal.species}_#{Date.today}.xlsx",
                  type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                  disposition: "attachment"
      end
    end
  end

  def new
    @feeding_record = @animal.feeding_records.build
  end

  def create
    @feeding_record = @animal.feeding_records.build(feeding_record_params)
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

    def set_feeding_record
      @feeding_record = @animal.feeding_records.find(params[:id])
    end

    def feeding_record_params
      params.require(:feeding_record).permit(:fed_at, :food_type, :amount_g, :note)
    end

    def feeding_records_xlsx(records)
      package = Axlsx::Package.new
      wb = package.workbook
      s = xlsx_styles(wb)
      row_styles = [ s[:datetime], s[:text], s[:number], s[:left], s[:text], s[:datetime] ]
      wb.add_worksheet(name: "먹이기록") do |sheet|
        sheet.add_row [ "급여 일시", "먹이 종류", "급여량(g)", "특이사항", "작성자", "입력일" ], style: s[:header]
        records.each do |r|
          sheet.add_row [
            r.fed_at,
            r.food_type,
            r.amount_g,
            r.note,
            r.created_by&.name,
            r.created_at
          ], style: row_styles
        end
        # 列幅を明示してExcelの####表示を防ぎ、ヘッダー行を固定・フィルタを付与
        sheet.column_widths 18, 16, 10, 36, 14, 18
        sheet.auto_filter = "A1:F1"
        sheet.sheet_view.pane do |pane|
          pane.state = :frozen
          pane.y_split = 1
          pane.active_pane = :bottom_left
        end
      end
      package.to_stream.read
    end
end
