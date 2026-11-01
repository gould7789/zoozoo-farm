# 관 목록·상세 담당
# zones 는 시드 데이터로 고정 — 읽기 전용(index, show)
class ZonesController < ApplicationController
  def index
    # 표시 순서를 고정한다 — 시드 데이터의 순서에 맞춘다
    display_order = [ "사랑새관", "앵무새관", "파충류관", "미니동물관", "야외동물체험관", "격리실" ]
    @zones = Zone.all.sort_by { |z| display_order.index(z.name) || 999 }
    # 관별 개체 수 합계를 한 번에 — 관마다 세면 N+1 이 된다
    @zone_counts = Animal.active.group(:zone_id).sum(:individual_count)
    # 홈 알림용 — 최신 건강 기록이 caution / danger 인 동물
    @alert_animals = Animal.with_alert_condition.limit(10)
    # 홈은 제목만 내보내므로 본문(리치텍스트)은 읽지 않는다
    @recent_notices = Notice.recent.limit(5).includes(:created_by)
  end

  def show
    @zone = Zone.find(params[:id])
    # 아코디언에 펼칠 것 — 숨김이 아닌 카테고리만
    @categories = @zone.animal_categories.where(hidden: false).order(:name)
    # 모달에 띄울 것 — 체크박스로 숨김을 끄고 켜므로 숨김 카테고리도 포함한다
    @all_categories = @zone.animal_categories.order(:name)
    # 동물을 한 번에 읽어 카테고리 ID 로 묶는다 (N+1 방지)
    #   @animals_by_category[category.id] → 그 카테고리의 동물
    #   @animals_by_category[nil]         → 미분류 동물
    @animals_by_category = @zone.animals.active
                                .includes(:health_records)
                                .with_attached_photo
                                .order(:species, :name)
                                .group_by(&:animal_category_id)
  end
end
