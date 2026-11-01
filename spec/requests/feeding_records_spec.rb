# FeedingRecordsController — 인증·권한 제어
# Staff·Admin 모두 작성 가능, 수정·삭제는 본인 기록만 (Admin 은 타인 기록도 조작 가능)
require "rails_helper"

RSpec.describe "FeedingRecords", type: :request do
  let(:zone)   { create(:zone) }
  let(:animal) { create(:animal, zone: zone) }
  let(:admin)  { create(:user, :admin) }
  let(:staff)  { create(:user) }
  let(:other)  { create(:user) }

  describe "GET /zones/:zone_id/animals/:animal_id/feeding_records" do
    context "비로그인" do
      before { get zone_animal_feeding_logs_path(zone, animal) }
      it_behaves_like "로그인이 필요하다"
    end

    context "로그인 상태" do
      before { sign_in(staff); get zone_animal_feeding_logs_path(zone, animal) }
      it { expect(response).to have_http_status(:ok) }
    end
  end

  describe "GET /zones/:zone_id/animals/:animal_id/feeding_records/new" do
    context "비로그인" do
      before { get new_zone_animal_feeding_log_path(zone, animal) }
      it_behaves_like "로그인이 필요하다"
    end

    context "로그인 상태" do
      before { sign_in(staff); get new_zone_animal_feeding_log_path(zone, animal) }
      it { expect(response).to have_http_status(:ok) }
    end
  end

  describe "POST /zones/:zone_id/animals/:animal_id/feeding_records" do
    let(:valid_params) { { feeding_record: { fed_at: Time.current, food_type: "펠렛" } } }

    context "비로그인" do
      before { post zone_animal_feeding_logs_path(zone, animal), params: valid_params }
      it_behaves_like "로그인이 필요하다"
    end

    context "Staff 가 작성" do
      before { sign_in(staff) }

      it "created_by 가 자기 ID 로 저장되고 목록으로 보낸다" do
        post zone_animal_feeding_logs_path(zone, animal), params: valid_params
        expect(response).to redirect_to(zone_animal_feeding_logs_path(zone, animal))
        expect(FeedingRecord.last.created_by).to eq(staff)
      end
    end
  end

  describe "GET /zones/:zone_id/animals/:animal_id/feeding_records/:id/edit" do
    context "본인 기록" do
      let(:feeding_record) { create(:feeding_record, animal: animal, created_by: staff) }
      before { sign_in(staff); get edit_zone_animal_feeding_log_path(zone, animal, feeding_record) }
      it { expect(response).to have_http_status(:ok) }
    end

    context "타인 기록" do
      let(:feeding_record) { create(:feeding_record, animal: animal, created_by: other) }
      before { sign_in(staff); get edit_zone_animal_feeding_log_path(zone, animal, feeding_record) }
      it_behaves_like "접근이 거부된다"
    end

    context "Admin 이 타인 기록에 접근" do
      let(:feeding_record) { create(:feeding_record, animal: animal, created_by: staff) }
      before { sign_in(admin); get edit_zone_animal_feeding_log_path(zone, animal, feeding_record) }
      it { expect(response).to have_http_status(:ok) }
    end
  end

  describe "PATCH /zones/:zone_id/animals/:animal_id/feeding_records/:id" do
    let(:valid_params) { { feeding_record: { food_type: "채소" } } }

    context "본인이 수정" do
      let(:feeding_record) { create(:feeding_record, animal: animal, created_by: staff) }
      before { sign_in(staff) }

      it "기록을 수정하고 목록으로 보낸다" do
        patch zone_animal_feeding_log_path(zone, animal, feeding_record), params: valid_params
        expect(response).to redirect_to(zone_animal_feeding_logs_path(zone, animal))
        expect(feeding_record.reload.food_type).to eq("채소")
      end
    end

    context "타인 기록 수정을 시도" do
      let(:feeding_record) { create(:feeding_record, animal: animal, created_by: other) }
      before { sign_in(staff); patch zone_animal_feeding_log_path(zone, animal, feeding_record), params: valid_params }
      it_behaves_like "접근이 거부된다"
    end
  end

  describe "DELETE /zones/:zone_id/animals/:animal_id/feeding_records/:id" do
    context "본인이 삭제" do
      let(:feeding_record) { create(:feeding_record, animal: animal, created_by: staff) }
      before { sign_in(staff) }

      it "기록을 삭제하고 목록으로 보낸다" do
        delete zone_animal_feeding_log_path(zone, animal, feeding_record)
        expect(response).to redirect_to(zone_animal_feeding_logs_path(zone, animal))
        expect { feeding_record.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "타인 기록 삭제를 시도" do
      let(:feeding_record) { create(:feeding_record, animal: animal, created_by: other) }
      before { sign_in(staff); delete zone_animal_feeding_log_path(zone, animal, feeding_record) }
      it_behaves_like "접근이 거부된다"
    end

    context "Admin 이 타인 기록을 삭제" do
      let(:feeding_record) { create(:feeding_record, animal: animal, created_by: staff) }
      before { sign_in(admin) }

      it "기록을 삭제하고 목록으로 보낸다" do
        delete zone_animal_feeding_log_path(zone, animal, feeding_record)
        expect(response).to redirect_to(zone_animal_feeding_logs_path(zone, animal))
        expect { feeding_record.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
