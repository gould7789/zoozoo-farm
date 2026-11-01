# AnimalPhotosController — 프로필 사진 삭제와 권한 제어
require "rails_helper"

RSpec.describe "AnimalPhotos", type: :request do
  let(:zone)   { create(:zone) }
  let(:admin)  { create(:user, :admin) }
  let(:staff)  { create(:user) }
  let(:animal) { create(:animal, zone: zone) }

  before do
    animal.photo.attach(fixture_file_upload("animal.jpg", "image/jpeg"))
  end

  describe "DELETE /zones/:zone_id/animals/:animal_id/photo" do
    context "비로그인" do
      it "로그인 화면으로 보내고 사진은 남는다" do
        delete zone_animal_photo_path(zone, animal)

        expect(response).to redirect_to(login_path)
        expect(animal.reload.photo).to be_attached
      end
    end

    # 동물 수정이 Admin 전용이라 사진 삭제도 같은 권한으로 맞춘다
    context "Staff 가 삭제를 시도" do
      before { sign_in(staff) }

      it "루트로 보내고 사진은 남는다" do
        delete zone_animal_photo_path(zone, animal)

        expect(response).to redirect_to(root_path)
        expect(animal.reload.photo).to be_attached
      end
    end

    context "Admin 이 삭제" do
      before { sign_in(admin) }

      it "사진을 떼고 수정 화면으로 돌아간다" do
        delete zone_animal_photo_path(zone, animal)

        expect(response).to redirect_to(edit_zone_animal_path(zone, animal))
        expect(animal.reload.photo).not_to be_attached
      end

      # 잡 큐가 영속화되지 않아(:async) 동기로 지운다 (notes/animal-photo.md)
      it "blob 도 그 자리에서 지워진다" do
        blob_id = animal.photo.blob.id

        delete zone_animal_photo_path(zone, animal)

        expect(ActiveStorage::Blob.exists?(blob_id)).to be false
      end

      # 관과 동물 조합이 어긋나면 RecordNotFound —
      # ApplicationController 의 rescue_from 이 루트로 보낸다
      it "다른 관의 동물은 삭제할 수 없다" do
        other_animal = create(:animal)
        other_animal.photo.attach(fixture_file_upload("animal.jpg", "image/jpeg"))

        delete zone_animal_photo_path(zone, other_animal)

        expect(response).to redirect_to(root_path)
        expect(other_animal.reload.photo).to be_attached
      end
    end
  end
end
