# 支出記録のCRUDを担当するコントローラー — Admin専用
class ExpenseRecordsController < ApplicationController
  before_action :require_admin
  before_action :set_expense_record, only: [ :edit, :update, :destroy ]

  def index
    all_records = ExpenseRecord.recent

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
end
