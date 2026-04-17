# 動物カテゴリのCRUDを担当するコントローラー
# 全アクションはAdmin専用 — Staffは参照のみ
class AnimalCategoriesController < ApplicationController
  before_action :set_zone
  before_action :require_admin

  # カテゴリ管理専用ページ
  def index
    @categories = @zone.animal_categories.order(:name)
    @new_category = @zone.animal_categories.build
  end

  def create
    @category = @zone.animal_categories.build(category_params)
    if @category.save
      redirect_to zone_animal_categories_path(@zone), notice: "카테고리를 추가했습니다."
    else
      redirect_to zone_animal_categories_path(@zone), alert: @category.errors.full_messages.to_sentence
    end
  end

  def edit
    @category = @zone.animal_categories.find(params[:id])
  end

  def update
    @category = @zone.animal_categories.find(params[:id])
    if @category.update(category_params)
      redirect_to zone_animal_categories_path(@zone), notice: "카테고리 이름을 수정했습니다."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @category = @zone.animal_categories.find(params[:id])
    @category.destroy!
    # カテゴリ削除後、所属動物のanimal_category_idはDBのON DELETE NULLIFYで自動的にNULLになる
    redirect_to zone_animal_categories_path(@zone), notice: "카테고리를 삭제했습니다. 해당 카테고리의 동물은 미분류로 이동되었습니다."
  end

  private

    def set_zone
      @zone = Zone.find(params[:zone_id])
    end

    def category_params
      params.require(:animal_category).permit(:name)
    end
end
