# 支出記録のCRUDを担当するコントローラー — Admin専用
class ExpenseRecordsController < ApplicationController
  before_action :require_admin
  before_action :set_expense_record, only: [ :edit, :update, :destroy ]

  def index
    all_records = ExpenseRecord.recent.includes(:created_by)

    # 年リスト（新しい順）
    @all_years = all_records.map { |er| er.spent_on.year }.uniq

    # 年月マップ { year => [month, ...] }（月は新しい順）
    @months_by_year = all_records.group_by { |er| er.spent_on.year }
                                 .transform_values { |rs| rs.map { |er| er.spent_on.month }.uniq }

    # 選択中の年（パラメータがなければ最新年）
    @selected_year = params[:year].present? ? params[:year].to_i : @all_years.first

    # 選択中の月（パラメータがなければ選択年の最新月）
    months_in_year = @months_by_year[@selected_year] || []
    @selected_month = params[:month].present? ? params[:month].to_i : months_in_year.first

    # 選択月のレコードのみ表示
    @expense_records = all_records.select { |er|
      er.spent_on.year == @selected_year && er.spent_on.month == @selected_month
    }

    respond_to do |format|
      format.html
      format.xlsx do
        filename = if @selected_year && @selected_month
          "지출기록_#{@selected_year}년#{ "%02d" % @selected_month }월.xlsx"
        else
          "지출기록_#{Date.today}.xlsx"
        end
        send_data expense_records_xlsx(@expense_records),
                  filename: filename,
                  type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                  disposition: "attachment"
      end
    end
  end

  def new
    @expense_record = ExpenseRecord.new
  end

  def create
    @expense_record = ExpenseRecord.new(expense_record_params)
    # created_byは必ずログイン中のAdminを設定
    @expense_record.created_by = current_user
    if @expense_record.save
      redirect_to expenses_path, notice: "지출 기록을 저장했습니다."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @expense_record.update(expense_record_params)
      redirect_to expenses_path, notice: "지출 기록을 수정했습니다."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @expense_record.destroy
    redirect_to expenses_path, notice: "지출 기록을 삭제했습니다."
  end

  private

    def set_expense_record
      @expense_record = ExpenseRecord.find(params[:id])
    end

    # ストロングパラメータ — created_byはコントローラーで強制設定するので除外
    def expense_record_params
      params.require(:expense_record).permit(:spent_on, :category, :amount, :description)
    end

    def expense_records_xlsx(records)
      package = Axlsx::Package.new
      wb = package.workbook
      s = xlsx_styles(wb)
      row_styles = [ s[:date], s[:text], s[:money], s[:left], s[:text] ]
      wb.add_worksheet(name: "지출기록") do |sheet|
        sheet.add_row [ "지출일", "카테고리", "금액(원)", "상세내용", "작성자" ], style: s[:header]
        records.each do |r|
          sheet.add_row [
            r.spent_on,
            I18n.t("enums.expense_record.category.#{r.category}"),
            r.amount,
            r.description,
            r.created_by&.name
          ], style: row_styles
        end
        # 列幅を明示してExcelの####表示を防ぎ、ヘッダー行を固定・フィルタを付与
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
