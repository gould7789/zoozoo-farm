# 売上記録のCRUDを担当するコントローラー — Admin専用
class SalesRecordsController < ApplicationController
  before_action :require_admin
  before_action :set_sales_record, only: [ :edit, :update, :destroy ]

  def index
    # 最新の売上日順に表示
    @sales_records = SalesRecord.recent
  end

  def new
    @sales_record = SalesRecord.new
  end

  def create
    @sales_record = SalesRecord.new(sales_record_params)
    # created_byは必ずログイン中のAdminを設定
    @sales_record.created_by = current_user
    if @sales_record.save
      redirect_to sales_records_path, notice: "매출 기록을 저장했습니다."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @sales_record.update(sales_record_params)
      redirect_to sales_records_path, notice: "매출 기록을 수정했습니다."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @sales_record.destroy
    redirect_to sales_records_path, notice: "매출 기록을 삭제했습니다."
  end

  private

    def set_sales_record
      @sales_record = SalesRecord.find(params[:id])
    end

    # ストロングパラメータ — created_byはコントローラーで強制設定するので除外
    def sales_record_params
      params.require(:sales_record).permit(:sold_on, :source, :amount, :note)
    end
end
