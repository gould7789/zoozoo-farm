# params 에서 Zone 과 Animal 을 해결한다
# HealthRecords / FeedingRecords 두 컨트롤러가 공유한다
module AnimalScoped
  extend ActiveSupport::Concern

  included do
    before_action :set_zone
    before_action :set_animal
    before_action :reject_exited_animal, only: [ :new, :create ]
  end

  private

    def set_zone
      @zone = Zone.find(params[:zone_id])
    end

    def set_animal
      @animal = @zone.animals.find(params[:animal_id])
    end

    # 내보낸 개체에는 기록을 추가할 수 없다. 막지 않으면 사망일 이후의 급여 기록이 에러 없이 저장되고, 나중에 폐사보고서를 쓸 때야 드러난다.
    # edit·update·destroy 는 막지 않는다 — 지난 기록의 오타를 고치는 것은 정당하다
    def reject_exited_animal
      return unless @animal.exited?

      redirect_to zone_animal_path(@zone, @animal),
                  alert: "내보낸 개체에는 기록을 추가할 수 없습니다."
    end
end
