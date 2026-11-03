# 동물 개체 CRUD
# 조회(show)는 Staff 와 Admin 공통, 등록·수정과 내보내기는 Admin 전용
# 폐사·분양은 사유와 날짜를 남기는 논리 삭제, 입력 실수만 purge 로 물리 삭제한다
# 판단 근거는 .claude/rules/notes/animal-lifecycle.md, notes/animal-photo.md, notes/xlsx-export.md
class AnimalsController < ApplicationController
  before_action :set_zone
  before_action :require_admin, only: [ :index, :new, :create, :edit, :update, :destroy, :restore, :purge ]
  before_action :set_animal,    only: [ :show, :edit, :update, :destroy, :restore, :purge ]

  # xlsx 내보내기 전용 — HTML 요청은 관 상세로 돌려보낸다
  def index
    respond_to do |format|
      format.xlsx do
        animals = @zone.animals.active
                               .includes(:animal_category)
                               .joins("LEFT JOIN animal_categories ON animal_categories.id = animals.animal_category_id")
                               .order("animal_categories.name ASC NULLS LAST, animals.species ASC, animals.name ASC NULLS LAST")
        send_data animals_xlsx(animals),
                  filename: "동물목록_#{@zone.name}_#{Date.current}.xlsx",
                  type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                  disposition: "attachment"
      end
      format.html { redirect_to zone_path(@zone) }
    end
  end

  def show
  end

  def new
    @animal = @zone.animals.build
    @categories = @zone.animal_categories.order(:name)
  end

  def create
    @animal = @zone.animals.build(animal_params)
    if @animal.save
      redirect_to zone_animal_path(@zone, @animal), notice: "동물을 등록했습니다."
    else
      @categories = @zone.animal_categories.order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @categories = @zone.animal_categories.order(:name)
    @saved_photo = @animal.photo
  end

  def update
    if @animal.update(animal_params)
      redirect_to zone_animal_path(@zone, @animal), notice: "동물 정보를 수정했습니다."
    else
      @categories = @zone.animal_categories.order(:name)
      # 검증 에러 때 @animal.photo 는 저장되지 않은 첨부를 가리킨다.
      # 저장된 사진을 따로 다시 읽지 않으면, 지워지지 않았는데 지워진 것처럼 보인다
      @saved_photo = Animal.find(@animal.id).photo
      render :edit, status: :unprocessable_entity
    end
  end

  # 내보내기 — 폐사 또는 분양. 기록은 남는다
  def destroy
    # active 와 exit_* 를 한 번에 쓴다. 따로 쓰면 중간 상태가 CHECK 에 걸린다
    @animal.assign_attributes(exit_params.merge(active: false))

    if @animal.save
      redirect_to zone_path(@zone), notice: "#{exit_label} 처리했습니다."
    else
      redirect_to zone_animal_path(@zone, @animal),
                  alert: @animal.errors.full_messages.to_sentence
    end
  end

  def restore
    @animal.restore!
    redirect_to zone_animal_path(@zone, @animal), notice: "다시 사육 중으로 되돌렸습니다."
  end

  # 입력 실수로 등록한 개체를 지운다. 되돌릴 수 없다
  def purge
    # 종명 확인을 서버에서 한다. 브라우저에서만 막으면 되돌릴 수 없는 조작이
    # 폼을 거치지 않은 요청에 그대로 열린다
    if params[:confirm_species] != @animal.species
      return redirect_to zone_animal_path(@zone, @animal),
                         alert: "종명이 일치하지 않아 삭제하지 않았습니다."
    end

    # 잡 워커가 없어 purge_later 의 잡이 사라진다 — 스토리지에 고아 파일이 남으므로
    # 동기로 먼저 지운다 (notes/animal-photo.md)
    @animal.photo.purge if @animal.photo.attached?
    @animal.destroy!
    redirect_to zone_path(@zone), notice: "동물을 완전히 삭제했습니다."
  end

  private

    def set_zone
      @zone = Zone.find(params[:zone_id])
    end

    def set_animal
      @animal = @zone.animals.find(params[:id])
    end

    def exit_params
      permitted = params.require(:animal).permit(:exit_reason, :exited_on, :exit_note)
      # enum 에 없는 값을 대입하면 ArgumentError 로 떨어진다 (common/rails.md).
      # nil 로 떨어뜨려 모델 검증이 사람이 읽을 메시지를 내게 한다
      permitted[:exit_reason] = nil unless Animal.exit_reasons.key?(permitted[:exit_reason])
      permitted
    end

    def exit_label
      @animal.exit_transferred? ? "분양" : "폐사"
    end

    # active 와 exit_* 는 폼에서 받지 않는다 — 내보내기는 destroy 액션만 거친다
    def animal_params
      params.require(:animal).permit(
        :name, :species, :gender, :birth_date,
        :acquired_at, :acquisition_note, :cites_grade, :note,
        :animal_category_id, :individual_count, :photo
      )
    end

    def animals_xlsx(animals)
      package = Axlsx::Package.new
      wb = package.workbook
      s = xlsx_styles(wb)
      # 열의 형에 맞춰 스타일을 붙인다 (금액은 오른쪽, 날짜는 가운데)
      row_styles = [ s[:text], s[:text], s[:text], s[:number], s[:text], s[:date], s[:date], s[:text], s[:left] ]
      wb.add_worksheet(name: "동물목록") do |sheet|
        sheet.add_row [ "분류", "이름", "종", "개체수", "성별", "생년월일", "입수일", "CITES 등급", "특이사항" ], style: s[:header]
        last_category = nil
        animals.each do |a|
          current_category = a.animal_category&.name || "미분류"
          # 분류명은 카테고리가 바뀐 행에만 쓴다 — 같은 카테고리 안은 비워 둔다
          category_cell = current_category == last_category ? nil : current_category
          last_category = current_category
          sheet.add_row [
            category_cell,
            a.name,
            a.species,
            a.individual_count,
            I18n.t("enums.animal.gender.#{a.gender}"),
            a.birth_date,
            a.acquired_at,
            I18n.t("enums.animal.cites_grade.#{a.cites_grade}"),
            a.note
          ], style: row_styles
        end
        # 폭을 명시하지 않으면 Excel 이 #### 로 가린다
        sheet.column_widths 12, 12, 16, 8, 8, 13, 13, 12, 30
        sheet.auto_filter = "A1:I1"
        sheet.sheet_view.pane do |pane|
          pane.state = :frozen
          pane.y_split = 1
          pane.active_pane = :bottom_left
        end
      end
      package.to_stream.read
    end
end
