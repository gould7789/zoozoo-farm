# FeedingRecordsControllerのリクエストテスト — 認証・権限制御を中心に検証する
# Staff/Admin共に作成可能、編集・削除は本人記録のみ（Adminは他者記録も操作可能）
require "rails_helper"

RSpec.describe "FeedingRecords", type: :request do
  let(:zone)   { create(:zone) }
  let(:animal) { create(:animal, zone: zone) }
  let(:admin)  { create(:user, :admin) }
  let(:staff)  { create(:user) }
  let(:other)  { create(:user) }

  describe "GET /zones/:zone_id/animals/:animal_id/feeding_records" do
    context "未ログイン" do
      before { get zone_animal_feeding_records_path(zone, animal) }
      it_behaves_like "ログインが必要"
    end

    context "ログイン済み" do
      before { sign_in(staff); get zone_animal_feeding_records_path(zone, animal) }
      it { expect(response).to have_http_status(:ok) }
    end
  end

  describe "GET /zones/:zone_id/animals/:animal_id/feeding_records/new" do
    context "未ログイン" do
      before { get new_zone_animal_feeding_record_path(zone, animal) }
      it_behaves_like "ログインが必要"
    end

    context "ログイン済み" do
      before { sign_in(staff); get new_zone_animal_feeding_record_path(zone, animal) }
      it { expect(response).to have_http_status(:ok) }
    end
  end

  describe "POST /zones/:zone_id/animals/:animal_id/feeding_records" do
    let(:valid_params) { { feeding_record: { fed_at: Time.current, food_type: "ペレット" } } }

    context "未ログイン" do
      before { post zone_animal_feeding_records_path(zone, animal), params: valid_params }
      it_behaves_like "ログインが必要"
    end

    context "Staffが作成" do
      before { sign_in(staff) }

      it "created_byが自分のIDで保存されて一覧ページにリダイレクトする" do
        post zone_animal_feeding_records_path(zone, animal), params: valid_params
        expect(response).to redirect_to(zone_animal_feeding_records_path(zone, animal))
        expect(FeedingRecord.last.created_by).to eq(staff)
      end
    end
  end

  describe "GET /zones/:zone_id/animals/:animal_id/feeding_records/:id/edit" do
    context "本人の記録" do
      let(:feeding_record) { create(:feeding_record, animal: animal, created_by: staff) }
      before { sign_in(staff); get edit_zone_animal_feeding_record_path(zone, animal, feeding_record) }
      it { expect(response).to have_http_status(:ok) }
    end

    context "他人の記録" do
      let(:feeding_record) { create(:feeding_record, animal: animal, created_by: other) }
      before { sign_in(staff); get edit_zone_animal_feeding_record_path(zone, animal, feeding_record) }
      it_behaves_like "アクセス拒否"
    end

    context "Adminが他人の記録にアクセス" do
      let(:feeding_record) { create(:feeding_record, animal: animal, created_by: staff) }
      before { sign_in(admin); get edit_zone_animal_feeding_record_path(zone, animal, feeding_record) }
      it { expect(response).to have_http_status(:ok) }
    end
  end

  describe "PATCH /zones/:zone_id/animals/:animal_id/feeding_records/:id" do
    let(:valid_params) { { feeding_record: { food_type: "野菜" } } }

    context "本人が更新" do
      let(:feeding_record) { create(:feeding_record, animal: animal, created_by: staff) }
      before { sign_in(staff) }

      it "記録を更新して一覧ページにリダイレクトする" do
        patch zone_animal_feeding_record_path(zone, animal, feeding_record), params: valid_params
        expect(response).to redirect_to(zone_animal_feeding_records_path(zone, animal))
        expect(feeding_record.reload.food_type).to eq("野菜")
      end
    end

    context "他人の記録を更新しようとする" do
      let(:feeding_record) { create(:feeding_record, animal: animal, created_by: other) }
      before { sign_in(staff); patch zone_animal_feeding_record_path(zone, animal, feeding_record), params: valid_params }
      it_behaves_like "アクセス拒否"
    end
  end

  describe "DELETE /zones/:zone_id/animals/:animal_id/feeding_records/:id" do
    context "本人が削除" do
      let(:feeding_record) { create(:feeding_record, animal: animal, created_by: staff) }
      before { sign_in(staff) }

      it "記録を削除して一覧ページにリダイレクトする" do
        delete zone_animal_feeding_record_path(zone, animal, feeding_record)
        expect(response).to redirect_to(zone_animal_feeding_records_path(zone, animal))
        expect { feeding_record.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "他人の記録を削除しようとする" do
      let(:feeding_record) { create(:feeding_record, animal: animal, created_by: other) }
      before { sign_in(staff); delete zone_animal_feeding_record_path(zone, animal, feeding_record) }
      it_behaves_like "アクセス拒否"
    end

    context "Adminが他人の記録を削除" do
      let(:feeding_record) { create(:feeding_record, animal: animal, created_by: staff) }
      before { sign_in(admin) }

      it "記録を削除して一覧ページにリダイレクトする" do
        delete zone_animal_feeding_record_path(zone, animal, feeding_record)
        expect(response).to redirect_to(zone_animal_feeding_records_path(zone, animal))
        expect { feeding_record.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
