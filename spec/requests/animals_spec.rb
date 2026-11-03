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

    let(:exit_params) do
      { animal: { exit_reason: "deceased", exited_on: "2026-03-14", exit_note: "노령으로 인한 쇠약" } }
    end

    context "Staff 가 내보내기를 시도" do
      before { sign_in(staff) }

      it "루트로 보낸다" do
        delete zone_animal_path(zone, animal), params: exit_params
        expect(response).to redirect_to(root_path)
      end
    end

    # Admin 이 내보내면 사유·날짜와 함께 active = false 가 된다 — 실제 DELETE 는 하지 않는다
    context "Admin 이 내보냄" do
      before { sign_in(admin) }

      it "사유와 날짜를 남기고 관 화면으로 보낸다" do
        animal   # let 은 지연 생성이라 블록 밖에서 먼저 만든다
        expect {
          delete zone_animal_path(zone, animal), params: exit_params
        }.not_to change(Animal, :count)

        expect(response).to redirect_to(zone_path(zone))
        expect(animal.reload).to have_attributes(
          active: false, exit_reason: "deceased", exited_on: Date.new(2026, 3, 14)
        )
      end

      it "날짜를 비우면 저장하지 않고 상세로 되돌린다" do
        delete zone_animal_path(zone, animal),
               params: { animal: { exit_reason: "deceased", exited_on: "" } }

        expect(response).to redirect_to(zone_animal_path(zone, animal))
        expect(animal.reload.active).to be true
      end

      # enum 에 없는 값은 ArgumentError 로 떨어지므로 500 이 되면 안 된다
      it "사유가 enum 밖이면 500 이 아니라 검증 에러로 돌려보낸다" do
        delete zone_animal_path(zone, animal),
               params: { animal: { exit_reason: "교환", exited_on: "2026-03-14" } }

        expect(response).to redirect_to(zone_animal_path(zone, animal))
        expect(animal.reload.active).to be true
      end
    end
  end

  describe "POST /zones/:zone_id/animals/:id/restore" do
    let(:animal) { create(:animal, :exited, zone: zone) }

    it "Staff 는 되돌릴 수 없다" do
      sign_in(staff)
      post restore_zone_animal_path(zone, animal)
      expect(response).to redirect_to(root_path)
    end

    it "Admin 이 되돌리면 내보낸 흔적이 지워진다" do
      sign_in(admin)
      post restore_zone_animal_path(zone, animal)

      expect(animal.reload).to have_attributes(
        active: true, exit_reason: nil, exited_on: nil, exit_note: nil
      )
    end
  end

  describe "DELETE /zones/:zone_id/animals/:id/purge" do
    let(:animal) { create(:animal, zone: zone) }

    it "Staff 는 완전 삭제할 수 없다" do
      sign_in(staff)
      animal
      expect {
        delete purge_zone_animal_path(zone, animal), params: { confirm_species: animal.species }
      }.not_to change(Animal, :count)
    end

    it "Admin 이 완전 삭제하면 행과 기록이 함께 사라진다" do
      sign_in(admin)
      create(:health_record, animal: animal, created_by: admin, recorded_on: Date.current)

      expect {
        delete purge_zone_animal_path(zone, animal), params: { confirm_species: animal.species }
      }.to change(Animal, :count).by(-1).and change(HealthRecord, :count).by(-1)
    end

    # 브라우저에서만 막으면 폼을 거치지 않은 요청에 그대로 열린다
    it "종명이 틀리면 지우지 않는다" do
      sign_in(admin)
      animal

      expect {
        delete purge_zone_animal_path(zone, animal), params: { confirm_species: "다른종" }
      }.not_to change(Animal, :count)

      expect(response).to redirect_to(zone_animal_path(zone, animal))
    end

    # purge_later 는 잡 워커가 없어 잡이 사라진다 — 스토리지에 파일이 남는다
    it "사진 blob 을 남기지 않는다" do
      sign_in(admin)
      animal.photo.attach(fixture_file_upload("animal.jpg", "image/jpeg"))

      expect {
        delete purge_zone_animal_path(zone, animal), params: { confirm_species: animal.species }
      }.to change(ActiveStorage::Blob, :count).by(-1)
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
