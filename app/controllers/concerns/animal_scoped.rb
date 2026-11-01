# params 에서 Zone 과 Animal 을 해결한다
# HealthRecords / FeedingRecords 두 컨트롤러가 공유한다
module AnimalScoped
  extend ActiveSupport::Concern

  included do
    before_action :set_zone
    before_action :set_animal
  end

  private

    def set_zone
      @zone = Zone.find(params[:zone_id])
    end

    def set_animal
      @animal = @zone.animals.find(params[:animal_id])
    end
end
