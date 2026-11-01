# 연월 필터가 붙은 목록의 공통 처리 — 매출·지출 두 화면에서 쓴다
# 대상 모델에 in_month 스코프와 available_year_months 가 있어야 한다
module MonthlyFilterable
  extend ActiveSupport::Concern

  private

    # 연월 선택 상태를 인스턴스 변수에 담고 해당 월의 레코드를 돌려준다
    def load_monthly_records(model)
      year_months = model.available_year_months

      @all_years      = year_months.map(&:first).uniq
      @months_by_year = year_months.group_by(&:first)
                                   .transform_values { |pairs| pairs.map(&:last) }

      @selected_year  = resolve_year(params[:year], @all_years)
      @selected_month = resolve_month(params[:month], @months_by_year[@selected_year])

      # 기록이 0건이거나 연월을 확정할 수 없으면 빈 릴레이션을 돌려준다
      return model.none if @selected_year.nil? || @selected_month.nil?

      model.in_month(@selected_year, @selected_month).recent.includes(:created_by)
    end

    # 없는 연도가 지정되면 최신 연도로 떨어뜨린다.
    # 부정한 값이 Date.new 에 넘어가 ArgumentError 가 되는 것도 여기서 막는다
    def resolve_year(param, years)
      year = param.presence&.to_i
      years.include?(year) ? year : years.first
    end

    # 없는 월이 지정되면 그 해의 최신 월로 떨어뜨린다
    def resolve_month(param, months)
      months = months.to_a
      month  = param.presence&.to_i
      months.include?(month) ? month : months.first
    end
end
