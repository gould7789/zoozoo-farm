# AnimalsController — 인증·권한 제어
require "rails_helper"

RSpec.describe "Animals", type: :request do
  let(:zone)  { create(:zone) }
  let(:admin) { create(:user, :admin) }
  let(:staff) { create(:user) }          # 팩토리 기본값이 staff

  describe "GET /zones/:zone_id/animals/:id" do
    let(:animal) { create(:animal, zone: zone) }

    context "비로그인" do
      it "로그인 화면으로 보낸다" do
        get zone_animal_path(zone, animal)
        expect(response).to redirect_to(login_path)
      end
    end

    context "로그인 상태" do
      before { sign_in(staff) }

      it "200을 반환한다" do
        get zone_animal_path(zone, animal)
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "GET /zones/:zone_id/animals/new" do
    context "Staff 가 접근" do
      before { sign_in(staff) }

      it "루트로 보낸다" do
        get new_zone_animal_path(zone)
        expect(response).to redirect_to(root_path)
      end
    end

    context "Admin 이 접근" do
      before { sign_in(admin) }

      it "200을 반환한다" do
        get new_zone_animal_path(zone)
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "POST /zones/:zone_id/animals" do
    let(:valid_params) { { animal: { species: "앵무새", gender: "unknown" } } }

    context "Staff 가 전송" do
      before { sign_in(staff) }

      it "루트로 보낸다" do
        post zone_animals_path(zone), params: valid_params
        expect(response).to redirect_to(root_path)
      end
    end

    context "Admin 이 전송" do
      before { sign_in(admin) }

      it "동물을 등록하고 리다이렉트한다" do
        post zone_animals_path(zone), params: valid_params
        expect(response).to redirect_to(zone_animal_path(zone, Animal.last))
      end
    end
  end

  describe "PATCH /zones/:zone_id/animals/:id" do
    let(:animal) { create(:animal, zone: zone) }
    let(:valid_params) { { animal: { species: "큰앵무" } } }

    context "Staff 가 수정을 시도" do
      before { sign_in(staff) }

      it "루트로 보낸다" do
        patch zone_animal_path(zone, animal), params: valid_params
        expect(response).to redirect_to(root_path)
      end
    end

    context "Admin 이 수정" do
      before { sign_in(admin) }

      it "동물 정보를 수정하고 상세로 보낸다" do
        patch zone_animal_path(zone, animal), params: valid_params
        expect(response).to redirect_to(zone_animal_path(zone, animal))
        expect(animal.reload.species).to eq("큰앵무")
      end
    end
  end

  describe "DELETE /zones/:zone_id/animals/:id" do
    let(:animal) { create(:animal, zone: zone) }

    context "Staff 가 삭제를 시도" do
      before { sign_in(staff) }

      it "루트로 보낸다" do
        delete zone_animal_path(zone, animal)
        expect(response).to redirect_to(root_path)
      end
    end

    # Admin 이 삭제하면 active = false 가 되고 관 화면으로 — 실제 DELETE 는 하지 않는다
    context "Admin 이 삭제" do
      before { sign_in(admin) }

      it "논리 삭제하고 관 화면으로 보낸다" do
        delete zone_animal_path(zone, animal)
        expect(response).to redirect_to(zone_path(zone))
        expect(animal.reload.active).to be false
      end
    end
  end

  describe "프로필 사진" do
    let(:animal)     { create(:animal, zone: zone) }
    let(:photo_file) { fixture_file_upload("animal.jpg", "image/jpeg") }

    it "Admin 은 사진과 함께 등록할 수 있다" do
      sign_in(admin)
      expect {
        post zone_animals_path(zone), params: {
          animal: { species: "해달", individual_count: 1, photo: photo_file }
        }
      }.to change(ActiveStorage::Attachment, :count).by(1)

      expect(Animal.find_by(species: "해달").photo).to be_attached
    end

    # content_type 은 신고값이 아니라 실제 바이트에서 판정되므로 진짜 HEIC 를 쓴다
    it "HEIC 는 거부되고 등록되지 않는다" do
      sign_in(admin)
      expect {
        post zone_animals_path(zone), params: {
          animal: {
            species: "해달",
            individual_count: 1,
            photo: fixture_file_upload("animal.heic", "image/heic")
          }
        }
      }.not_to change(Animal, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("HEIC")
    end

    # 배포는 proxy 경유 — redirect 면 스토리지 도메인으로 302 하고 CSP 에 막힌다
    it "상세 화면이 proxy 경유 URL 로 이미지를 낸다" do
      animal.photo.attach(photo_file)
      sign_in(staff)

      get zone_animal_path(zone, animal)

      expect(response.body).to include("/rails/active_storage/representations/proxy/")
    end

    it "수정 폼에 사진 입력 칸과 자르기 컨트롤러가 나온다" do
      sign_in(admin)

      get edit_zone_animal_path(zone, animal)

      expect(response.body).to include("animal[photo]")
      expect(response.body).to include("photo-crop")
      expect(response.body).to include('data-photo-crop-target="dialog"')
    end

    # 저장 전에 고른 사진을 취소하는 버튼 — 서버에 아무것도 보내지 않으므로
    # button 형이고, 처음에는 숨겨 두고 JS 가 보여준다
    it "등록 폼에도 선택 취소 버튼이 숨은 상태로 나온다" do
      sign_in(admin)

      get new_zone_animal_path(zone)

      # 속성 순서에 의존하지 않도록 CSS 선택자로 확인한다
      assert_select 'button[type="button"][hidden][data-photo-crop-target="clear"][data-action="photo-crop#clear"]'
    end

    # 검증 에러로 다시 그릴 때 @animal.photo 는 미저장 첨부를 가리킨다 (notes/animal-photo.md)
    it "검증 에러로 다시 그려도 저장된 사진과 삭제 버튼이 남는다" do
      sign_in(admin)
      animal.photo.attach(photo_file)

      patch zone_animal_path(zone, animal), params: {
        animal: { species: animal.species, photo: fixture_file_upload("animal.heic", "image/heic") }
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("HEIC")
      # 저장된 사진이 그대로이고 그 삭제 버튼도 나와 있는지
      expect(animal.reload.photo).to be_attached
      expect(response.body).to include(zone_animal_photo_path(zone, animal))
    end

    # 삭제 동작 자체는 spec/requests/animal_photos_spec.rb 에서 본다
    it "사진이 있을 때만 수정 폼에 삭제 버튼이 나오고 확인 모달을 거친다" do
      sign_in(admin)
      animal.photo.attach(photo_file)

      get edit_zone_animal_path(zone, animal)
      expect(response.body).to include(zone_animal_photo_path(zone, animal))
      expect(response.body).to include('data-turbo-confirm="사진을 삭제하시겠습니까?"')

      animal.photo.purge
      get edit_zone_animal_path(zone, animal)
      expect(response.body).not_to include(zone_animal_photo_path(zone, animal))
    end

    # 아바타를 누르면 원본을 볼 수 있다 — 모달은 body 직하에 렌더된다
    it "상세 화면에 원본 모달이 나온다" do
      animal.photo.attach(photo_file)
      sign_in(staff)

      get zone_animal_path(zone, animal)

      expect(response.body).to include("photo-modal")
    end
  end
end
