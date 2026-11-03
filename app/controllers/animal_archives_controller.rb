# 내보낸 개체 보관 — 폐사·분양한 개체를 사진 카드로 다시 본다
# 조회는 Staff·Admin 공통. 동물 상세가 이미 공통이고 「그 아이 언제 죽었지」는 둘 다 묻는다
# 판단 근거는 .claude/rules/notes/animal-lifecycle.md
class AnimalArchivesController < ApplicationController
  def index
    @reason  = Animal.exit_reasons.key?(params[:reason]) ? params[:reason] : nil
    @animals = Animal.exited
                     .includes(:zone)
                     .with_attached_photo
                     .order(exited_on: :desc, species: :asc)
    @animals = @animals.where(exit_reason: @reason) if @reason
  end
end
