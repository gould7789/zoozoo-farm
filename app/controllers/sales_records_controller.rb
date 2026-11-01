# 매출 기록 CRUD — Admin 전용
# xlsx 내보내기 판단은 .claude/rules/notes/xlsx-export.md
class SalesRecordsController < ApplicationController
  include MonthlyFilterable

  before_action :require_admin
  before_action :set_sales_record, only: [ :edit, :update, :destroy ]

  def index
    @sales_records = load_monthly_records(SalesRecord)

    respond_to do |format|
      format.html
      format.xlsx do
        filename = if @selected_year && @selected_month
          "매출기록_#{@selected_year}년#{ "%02d" % @selected_month }월.xlsx"
        else
          "매출기록_#{Date.current}.xlsx"
        end
        send_data sales_records_xlsx(@sales_records),
                  filename: filename,
                  type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                  disposition: "attachment"
      end
    end
  end

  def new
    @sales_record = SalesRecord.new
  end

  def create
    @sales_record = SalesRecord.new(sales_record_params)
    # created_by 는 폼에서 받지 않고 로그인한 Admin 으로 강제한다
    @sales_record.created_by = current_user
    if @sales_record.save
      redirect_to sales_path, notice: "매출 기록을 저장했습니다."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @sales_record.update(sales_record_params)
      redirect_to sales_path, notice: "매출 기록을 수정했습니다."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @sales_record.destroy
    redirect_to sales_path, notice: "매출 기록을 삭제했습니다."
  end

  private

    def set_sales_record
      @sales_record = SalesRecord.find(params[:id])
    end

    # created_by 는 컨트롤러에서 강제하므로 폼에서 받지 않는다
    def sales_record_params
      params.require(:sales_record).permit(:sold_on, :source, :amount, :note)
    end

    def sales_records_xlsx(records)
      package = Axlsx::Package.new
      wb = package.workbook
      s = xlsx_styles(wb)
      row_styles = [ s[:date], s[:text], s[:money], s[:left], s[:text] ]
      wb.add_worksheet(name: "매출기록") do |sheet|
        sheet.add_row [ "매출일", "판매처", "금액(원)", "특이사항", "작성자" ], style: s[:header]
        records.each do |r|
          sheet.add_row [
            r.sold_on,
            I18n.t("enums.sales_record.source.#{r.source}"),
            r.amount,
            r.note,
            r.created_by&.name
          ], style: row_styles
        end
        # 폭을 명시하지 않으면 Excel 이 #### 로 가린다
        sheet.column_widths 13, 14, 14, 36, 14
        sheet.auto_filter = "A1:E1"
        sheet.sheet_view.pane do |pane|
          pane.state = :frozen
          pane.y_split = 1
          pane.active_pane = :bottom_left
        end
      end
      package.to_stream.read
    end
end
