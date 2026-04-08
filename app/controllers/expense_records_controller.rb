# 支出記録のCRUDを担当するコントローラー — Admin専用
class ExpenseRecordsController < ApplicationController
  before_action :require_admin
  before_action :set_expense_record, only: [ :edit, :update, :destroy ]

  def index
    # 最新の支出日順に表示
    @expense_records = ExpenseRecord.recent
  end

  def new
    @expense_record = ExpenseRecord.new
  end

  def create
    @expense_record = ExpenseRecord.new(expense_record_params)
    # created_byは必ずログイン中のAdminを設定
    @expense_record.created_by = current_user
    if @expense_record.save
      redirect_to expense_records_path, notice: "지출 기록을 저장했습니다."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @expense_record.update(expense_record_params)
      redirect_to expense_records_path, notice: "지출 기록을 수정했습니다."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @expense_record.destroy
    redirect_to expense_records_path, notice: "지출 기록을 삭제했습니다."
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
