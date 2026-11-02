require "rails_helper"

RSpec.describe Animal, type: :model do
  describe "검증" do
    it { is_expected.to validate_presence_of(:species) }
    it { is_expected.to validate_length_of(:species).is_at_most(100) }
    it { is_expected.to validate_length_of(:name).is_at_most(100) }
    it { is_expected.to validate_numericality_of(:individual_count).only_integer.is_greater_than_or_equal_to(1) }
  end

  describe "연관" do
    it { is_expected.to belong_to(:zone) }
    it { is_expected.to belong_to(:animal_category).optional }
  end

  describe "Enum" do
    it { is_expected.to define_enum_for(:gender).with_values(male: 0, female: 1, unknown: 2) }
    it { is_expected.to define_enum_for(:cites_grade).with_values(none: 0, grade_i: 1, grade_ii: 2, grade_iii: 3).with_prefix(:cites) }
  end

  describe "기본값" do
    subject(:animal) { Animal.new }

    it "gender 의 기본값은 unknown" do
      expect(animal.gender).to eq("unknown")
    end

    it "cites_grade 의 기본값은 none" do
      expect(animal.cites_grade).to eq("none")
    end

    it "active 의 기본값은 true" do
      expect(animal.active).to be true
    end

    it "individual_count 의 기본값은 1" do
      expect(animal.individual_count).to eq(1)
    end
  end

  describe "#age" do
    it "생년월일이 nil 이면 nil 을 반환한다" do
      expect(build(:animal, birth_date: nil).age).to be_nil
    end

    it "한국식 나이 — 태어난 해를 1살로 센다" do
      travel_to Time.utc(2026, 6, 1) do
        expect(build(:animal, birth_date: Date.new(2026, 5, 1)).age).to eq(1)
        expect(build(:animal, birth_date: Date.new(2020, 5, 1)).age).to eq(7)
      end
    end

    # KST 의 1/1 00:00~09:00 은 UTC 에서는 아직 전년이라,
    # UTC 기준으로 연도를 보면 나이가 1살 어긋난다
    context "연말연시 경계" do
      let(:birth_date) { Date.new(2020, 5, 1) }

      it "1월 1일 새벽(KST)에는 더해진 나이를 반환한다" do
        travel_to Time.utc(2026, 12, 31, 23, 30) do # = 2027-01-01 08:30 KST
          expect(build(:animal, birth_date: birth_date).age).to eq(8)
        end
      end

      it "12월 31일 밤(KST)에는 아직 더해지지 않은 나이를 반환한다" do
        travel_to Time.utc(2026, 12, 31, 14, 30) do # = 2026-12-31 23:30 KST
          expect(build(:animal, birth_date: birth_date).age).to eq(7)
        end
      end
    end
  end

  describe "프로필 사진" do
    subject(:animal) { build(:animal) }

    def attach_photo(filename:, content_type:, io: StringIO.new("dummy"))
      animal.photo.attach(io: io, filename: filename, content_type: content_type)
    end

    it "사진이 없어도 유효하다" do
      expect(animal).to be_valid
    end

    %w[image/jpeg image/png image/webp].each do |type|
      it "#{type} 은 받아들인다" do
        attach_photo(filename: "photo", content_type: type)
        expect(animal).to be_valid
      end
    end

    %w[image/heic image/heif image/gif application/pdf].each do |type|
      it "#{type} 은 거부한다" do
        attach_photo(filename: "photo", content_type: type)
        expect(animal).not_to be_valid
        expect(animal.errors[:photo]).to be_present
      end
    end

    it "거부 메시지가 한국어로 허용 형식을 안내한다" do
      attach_photo(filename: "photo.heic", content_type: "image/heic")
      animal.valid?
      expect(animal.errors[:photo].join).to include("JPG")
    end

    it "상한과 같은 크기는 받아들인다" do
      attach_photo(filename: "photo.jpg", content_type: "image/jpeg")
      allow(animal.photo.blob).to receive(:byte_size).and_return(Animal::MAX_PHOTO_BYTES)
      expect(animal).to be_valid
    end

    # 15MB 실파일을 매번 쓰면 느려지므로 byte_size 를 스텁한다.
    # 검증하려는 건 분기이고 업로드 경로가 아니다.
    it "상한을 넘는 크기는 거부한다" do
      attach_photo(filename: "photo.jpg", content_type: "image/jpeg")
      allow(animal.photo.blob).to receive(:byte_size).and_return(Animal::MAX_PHOTO_BYTES + 1)
      expect(animal).not_to be_valid
      expect(animal.errors[:photo].join).to include("15MB")
    end

    it "실제 이미지를 첨부해 저장할 수 있다" do
      animal.photo.attach(
        io: Rails.root.join("spec/fixtures/files/animal.jpg").open,
        filename: "animal.jpg",
        content_type: "image/jpeg"
      )
      expect(animal.save).to be true
      expect(animal.reload.photo).to be_attached
    end

    it "variant 가 정의돼 있다" do
      animal.photo.attach(
        io: Rails.root.join("spec/fixtures/files/animal.jpg").open,
        filename: "animal.jpg",
        content_type: "image/jpeg"
      )
      animal.save!
      expect { animal.photo.variant(:thumb).processed }.not_to raise_error
      expect { animal.photo.variant(:detail).processed }.not_to raise_error
    end
  end

  describe "스코프" do
    it ".active 는 논리 삭제되지 않은 동물만 반환한다" do
      zone = Zone.create!(name: "테스트관")
      active_animal   = Animal.create!(zone: zone, species: "앵무새", active: true)
      inactive_animal = Animal.create!(zone: zone, species: "큰앵무", active: false)

      expect(Animal.active).to include(active_animal)
      expect(Animal.active).not_to include(inactive_animal)
    end

    describe ".with_alert_condition" do
      let(:user) { create(:user) }

      it "최신 건강 기록이 caution 인 동물을 반환한다" do
        animal = create(:animal)
        create(:health_record, animal: animal, created_by: user, condition: :caution, recorded_on: Date.today)

        expect(Animal.with_alert_condition).to include(animal)
      end

      it "최신 건강 기록이 danger 인 동물을 반환한다" do
        animal = create(:animal)
        create(:health_record, animal: animal, created_by: user, condition: :danger, recorded_on: Date.today)

        expect(Animal.with_alert_condition).to include(animal)
      end

      it "최신 건강 기록이 normal 인 동물은 반환하지 않는다" do
        animal = create(:animal)
        create(:health_record, animal: animal, created_by: user, condition: :normal, recorded_on: Date.today)

        expect(Animal.with_alert_condition).not_to include(animal)
      end

      it "건강 기록이 없는 동물은 반환하지 않는다" do
        animal = create(:animal)

        expect(Animal.with_alert_condition).not_to include(animal)
      end

      it "지난 기록이 caution 이어도 최신이 normal 이면 반환하지 않는다" do
        animal = create(:animal)
        create(:health_record, animal: animal, created_by: user, condition: :caution, recorded_on: 3.days.ago)
        create(:health_record, animal: animal, created_by: user, condition: :normal,  recorded_on: Date.today)

        expect(Animal.with_alert_condition).not_to include(animal)
      end

      it "지난 기록이 normal 이어도 최신이 danger 면 반환한다" do
        animal = create(:animal)
        create(:health_record, animal: animal, created_by: user, condition: :normal, recorded_on: 3.days.ago)
        create(:health_record, animal: animal, created_by: user, condition: :danger, recorded_on: Date.today)

        expect(Animal.with_alert_condition).to include(animal)
      end

      it "active = false 인 동물은 반환하지 않는다" do
        animal = create(:animal, active: false)
        create(:health_record, animal: animal, created_by: user, condition: :danger, recorded_on: Date.today)

        expect(Animal.with_alert_condition).not_to include(animal)
      end
    end
  end

  describe "DB 제약" do
    it_behaves_like "DB 가 범위 밖 enum 값을 거부한다", :gender, 9, "chk_animals_gender"
    it_behaves_like "DB 가 범위 밖 enum 값을 거부한다", :cites_grade, 9, "chk_animals_cites_grade"
  end
end
