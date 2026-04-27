# 売上記録のCRUDを担当するコントローラー — Admin専用
class SalesRecordsController < ApplicationController
  before_action :require_admin
  before_action :set_sales_record, only: [ :edit, :update, :destroy ]

  def index
    all_records = SalesRecord.recent

    # 年リスト（新しい順）
    @all_years = all_records.map { |sr| sr.sold_on.year }.uniq

    # 年月マップ { year => [month, ...] }（月は新しい順）
    @months_by_year = all_records.group_by { |sr| sr.sold_on.year }
                                 .transform_values { |rs| rs.map { |sr| sr.sold_on.month }.uniq }

    # 選択中の年（パラメータがなければ最新年）
    @selected_year = params[:year].present? ? params[:year].to_i : @all_years.first

    # 選択中の月（パラメータがなければ選択年の最新月）
    months_in_year = @months_by_year[@selected_year] || []
    @selected_month = params[:month].present? ? params[:month].to_i : months_in_year.first

    # 選択月のレコードのみ表示
    @sales_records = all_records.select { |sr|
      sr.sold_on.year == @selected_year && sr.sold_on.month == @selected_month
    }

    respond_to do |format|
      format.html
      format.csv do
        filename = if @selected_year && @selected_month
          "매출기록_#{@selected_year}년#{ "%02d" % @selected_month }월.csv"
        else
          "매출기록_#{Date.today}.csv"
        end
        send_data sales_records_csv(@sales_records),
                  filename: filename,
                  type: "text/csv; charset=utf-8",
                  disposition: "attachment"
      end
    end
  end

  def new
    @sales_record = SalesRecord.new
  end

  def create
    @sales_record = SalesRecord.new(sales_record_params)
    # created_byは必ずログイン中のAdminを設定
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

    # ストロングパラメータ — created_byはコントローラーで強制設定するので除外
    def sales_record_params
      params.require(:sales_record).permit(:sold_on, :source, :amount, :note)
    end

    def sales_records_csv(records)
      "\xEF\xBB\xBF" + CSV.generate(encoding: "UTF-8") do |csv|
        csv << [ "매출일", "판매처", "금액(원)", "특이사항", "작성자" ]
        records.each do |r|
          csv << [
            r.sold_on.strftime("%Y-%m-%d"),
            I18n.t("enums.sales_record.source.#{r.source}"),
            r.amount,
            r.note,
            r.created_by&.name
          ]
        end
      end
    end
end
