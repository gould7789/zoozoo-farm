# 動物個体のCRUDを担当するコントローラー
# 閲覧（show）はStaff/Admin共通、作成・編集・削除はAdmin専用
# 削除はactive=falseの論理削除 — 物理削除は行わない
class AnimalsController < ApplicationController
  before_action :set_zone
  # 新規登録・作成・編集・更新・削除はAdmin専用
  before_action :require_admin, only: [ :new, :create, :edit, :update, :destroy ]
  before_action :set_animal,    only: [ :show, :edit, :update, :destroy ]

  def show
  end

  def new
    # 館に紐づいた新規動物インスタンスをビルド
    @animal = @zone.animals.build
  end

  def create
    @animal = @zone.animals.build(animal_params)
    if @animal.save
      redirect_to zone_animal_path(@zone, @animal), notice: "동물을 등록했습니다."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @animal.update(animal_params)
      redirect_to zone_animal_path(@zone, @animal), notice: "동물 정보를 수정했습니다."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    # 物理削除ではなくactive=falseにして履歴を保持する
    @animal.update!(active: false)
    redirect_to zone_path(@zone), notice: "동물을 삭제했습니다."
  end

  private

    def set_zone
      @zone = Zone.find(params[:zone_id])
    end

    def set_animal
      @animal = @zone.animals.find(params[:id])
    end

    # ストロングパラメータ — activeは更新対象外
    def animal_params
      params.require(:animal).permit(
        :name, :species, :gender, :birth_date,
        :acquired_at, :acquisition_note, :cites_grade, :note
      )
    end
end
