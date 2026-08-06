# 年月フィルタ付き一覧の共通処理 — 売上・支出の両画面で使う
# 対象モデルに in_month スコープと available_year_months が実装されていることを前提とする
module MonthlyFilterable
  extend ActiveSupport::Concern

  private

    # 年月の選択状態をインスタンス変数に設定し、対象月のレコードを返す
    def load_monthly_records(model)
      year_months = model.available_year_months

      @all_years      = year_months.map(&:first).uniq
      @months_by_year = year_months.group_by(&:first)
                                   .transform_values { |pairs| pairs.map(&:last) }

      @selected_year  = resolve_year(params[:year], @all_years)
      @selected_month = resolve_month(params[:month], @months_by_year[@selected_year])

      # 記録が1件もない、または年月が確定できない場合は空のリレーションを返す
      return model.none if @selected_year.nil? || @selected_month.nil?

      model.in_month(@selected_year, @selected_month).recent.includes(:created_by)
    end

    # 存在しない年が指定された場合は最新年にフォールバックする
    # 不正な値がDate.newに渡ってArgumentErrorになるのを防ぐ役割も持つ
    def resolve_year(param, years)
      year = param.presence&.to_i
      years.include?(year) ? year : years.first
    end

    # 存在しない月が指定された場合はその年の最新月にフォールバックする
    def resolve_month(param, months)
      months = months.to_a
      month  = param.presence&.to_i
      months.include?(month) ? month : months.first
    end
end
