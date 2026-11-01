# 동물 카테고리 CRUD
# 전체 액션이 Admin 전용 — Staff 는 조회만 한다
class AnimalCategoriesController < ApplicationController
  before_action :set_zone
  before_action :require_admin

  def create
    @category = @zone.animal_categories.build(category_params)
    if @category.save
      @all_categories = @zone.animal_categories.order(:name)
      load_accordion_data
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to zone_path(@zone), notice: "카테고리를 추가했습니다." }
      end
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.update("category_add_error", @category.errors.full_messages.to_sentence) }
        format.html { redirect_to zone_path(@zone), alert: @category.errors.full_messages.to_sentence }
      end
    end
  end

  def update
    @category = @zone.animal_categories.find(params[:id])
    if @category.update(category_params)
      load_accordion_data
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to zone_path(@zone), notice: "카테고리 이름을 수정했습니다." }
      end
    else
      respond_to do |format|
        # update 가 아니라 replace — update 는 innerHTML 만 갈아끼우므로
        # partial 의 루트 div 가 이중이 되고 padding 이 겹쳐 행이 들여쓰기된다
        format.turbo_stream { render turbo_stream: turbo_stream.replace("category_row_#{@category.id}", partial: "animal_categories/category_row", locals: { category: @category, zone: @zone, editing: true }) }
        format.html { redirect_to zone_path(@zone), alert: @category.errors.full_messages.to_sentence }
      end
    end
  end

  def destroy
    @category = @zone.animal_categories.find(params[:id])
    @category.destroy!
    # 소속 동물의 animal_category_id 는 DB 의 ON DELETE NULLIFY 로 알아서 NULL 이 된다
    redirect_to zone_path(@zone), notice: "카테고리를 삭제했습니다. 해당 카테고리의 동물은 미분류로 이동되었습니다."
  end

  # 숨김 플래그를 뒤집는다 — Turbo Stream 으로 모달을 닫지 않고 DOM 만 갱신한다
  def toggle
    @category = @zone.animal_categories.find(params[:id])
    @category.update!(hidden: !@category.hidden)
    respond_to do |format|
      format.turbo_stream do
        @all_categories = @zone.animal_categories.order(:name)
        load_accordion_data
      end
      format.html { redirect_to zone_path(@zone) }
    end
  end

  private

    def set_zone
      @zone = Zone.find(params[:zone_id])
    end

    def category_params
      params.require(:animal_category).permit(:name)
    end

    # 아코디언을 다시 그리는 데 필요한 데이터 — create / update / toggle 공통.
    # includes(:health_records) 는 아코디언이 latest_condition 을 부를 때의 N+1 을 막는다
    def load_accordion_data
      @categories = @zone.animal_categories.where(hidden: false).order(:name)
      @animals_by_category = @zone.animals.active
                                  .includes(:health_records)
                                  .with_attached_photo
                                  .order(:species, :name)
                                  .group_by(&:animal_category_id)
    end
end
