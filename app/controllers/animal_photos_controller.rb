# 동물 프로필 사진 삭제 — 동물 수정과 마찬가지로 Admin 전용
# 판단 근거는 .claude/rules/notes/animal-photo.md
class AnimalPhotosController < ApplicationController
  before_action :require_admin
  before_action :set_animal

  def destroy
    # purge_later 가 아니라 purge — 잡 큐가 영속화되지 않아(:async)
    # 인스턴스가 잠드는 시점에 잡이 사라지고 고아 파일이 남는다
    @animal.photo.purge
    redirect_to edit_zone_animal_path(@zone, @animal), notice: "사진을 삭제했습니다."
  end

  private

    # 관을 거쳐 찾는다 — URL 의 관과 동물 조합이 어긋나면 404 로 떨군다
    def set_animal
      @zone   = Zone.find(params[:zone_id])
      @animal = @zone.animals.find(params[:animal_id])
    end
end
