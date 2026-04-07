# FeedingRecordsControllerのリクエストテスト — 認証・権限制御を中心に検証する
# Staff/Admin共に作成可能、編集・削除は本人記録のみ（Adminは他者記録も操作可能）
require "rails_helper"

RSpec.describe "FeedingRecords", type: :request do
  let(:zone)   { create(:zone) }
  let(:animal) { create(:animal, zone: zone) }
  let(:admin)  { create(:user, :admin) }
  let(:staff)  { create(:user) }           # デフォルトはstaffロール
  let(:other)  { create(:user) }           # 別のStaffユーザー

  describe "GET /zones/:zone_id/animals/:animal_id/feeding_records" do
    # 未ログインはログインページへ強制リダイレクト
    context "未ログイン" do
      it "ログインページにリダイレクトする" do
        get zone_animal_feeding_records_path(zone, animal)
        expect(response).to redirect_to(login_path)
      end
    end

    # Staff/Admin共に一覧閲覧可能
    context "ログイン済み" do
      before { sign_in(staff) }

      it "200を返す" do
        get zone_animal_feeding_records_path(zone, animal)
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "GET /zones/:zone_id/animals/:animal_id/feeding_records/new" do
    # 未ログインはログインページへ強制リダイレクト
    context "未ログイン" do
      it "ログインページにリダイレクトする" do
        get new_zone_animal_feeding_record_path(zone, animal)
        expect(response).to redirect_to(login_path)
      end
    end

    # Staff/Admin共に新規作成フォームにアクセス可能
    context "ログイン済み" do
      before { sign_in(staff) }

      it "200を返す" do
        get new_zone_animal_feeding_record_path(zone, animal)
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "POST /zones/:zone_id/animals/:animal_id/feeding_records" do
    let(:valid_params) do
      { feeding_record: { fed_at: Time.current, food_type: "ペレット" } }
    end

    # 未ログインはログインページへ強制リダイレクト
    context "未ログイン" do
      it "ログインページにリダイレクトする" do
        post zone_animal_feeding_records_path(zone, animal), params: valid_params
        expect(response).to redirect_to(login_path)
      end
    end

    # Staffが作成すると自分のcreated_byで保存される
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
    # 自分の記録はedit可能
    context "本人の記録" do
      let(:feeding_record) { create(:feeding_record, animal: animal, created_by: staff) }
      before { sign_in(staff) }

      it "200を返す" do
        get edit_zone_animal_feeding_record_path(zone, animal, feeding_record)
        expect(response).to have_http_status(:ok)
      end
    end

    # 他人の記録はedit不可 — ルートへリダイレクト
    context "他人の記録" do
      let(:feeding_record) { create(:feeding_record, animal: animal, created_by: other) }
      before { sign_in(staff) }

      it "ルートにリダイレクトする" do
        get edit_zone_animal_feeding_record_path(zone, animal, feeding_record)
        expect(response).to redirect_to(root_path)
      end
    end

    # Adminは他人の記録もedit可能
    context "Adminが他人の記録にアクセス" do
      let(:feeding_record) { create(:feeding_record, animal: animal, created_by: staff) }
      before { sign_in(admin) }

      it "200を返す" do
        get edit_zone_animal_feeding_record_path(zone, animal, feeding_record)
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "PATCH /zones/:zone_id/animals/:animal_id/feeding_records/:id" do
    let(:valid_params) { { feeding_record: { food_type: "野菜" } } }

    # 自分の記録は更新可能
    context "本人が更新" do
      let(:feeding_record) { create(:feeding_record, animal: animal, created_by: staff) }
      before { sign_in(staff) }

      it "記録を更新して一覧ページにリダイレクトする" do
        patch zone_animal_feeding_record_path(zone, animal, feeding_record), params: valid_params
        expect(response).to redirect_to(zone_animal_feeding_records_path(zone, animal))
        expect(feeding_record.reload.food_type).to eq("野菜")
      end
    end

    # 他人の記録は更新不可
    context "他人の記録を更新しようとする" do
      let(:feeding_record) { create(:feeding_record, animal: animal, created_by: other) }
      before { sign_in(staff) }

      it "ルートにリダイレクトする" do
        patch zone_animal_feeding_record_path(zone, animal, feeding_record), params: valid_params
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "DELETE /zones/:zone_id/animals/:animal_id/feeding_records/:id" do
    # 自分の記録は削除可能
    context "本人が削除" do
      let(:feeding_record) { create(:feeding_record, animal: animal, created_by: staff) }
      before { sign_in(staff) }

      it "記録を削除して一覧ページにリダイレクトする" do
        delete zone_animal_feeding_record_path(zone, animal, feeding_record)
        expect(response).to redirect_to(zone_animal_feeding_records_path(zone, animal))
        expect { feeding_record.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    # 他人の記録は削除不可
    context "他人の記録を削除しようとする" do
      let(:feeding_record) { create(:feeding_record, animal: animal, created_by: other) }
      before { sign_in(staff) }

      it "ルートにリダイレクトする" do
        delete zone_animal_feeding_record_path(zone, animal, feeding_record)
        expect(response).to redirect_to(root_path)
      end
    end

    # Adminは他人の記録も削除可能
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
