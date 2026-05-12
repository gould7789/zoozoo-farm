# ZoneとAnimalをparamsから解決するConcern
# HealthRecords / FeedingRecords の2コントローラーで共通利用
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
