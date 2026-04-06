# AnimalsControllerのリクエストテスト — 認証・権限制御を中心に検証する
require "rails_helper"

RSpec.describe "Animals", type: :request do
  let(:zone)  { create(:zone) }
  let(:admin) { create(:user, :admin) }
  let(:staff) { create(:user) }          # デフォルトはstaffロール

  describe "GET /zones/:zone_id/animals/:id" do
    let(:animal) { create(:animal, zone: zone) }

    # 未ログインはログインページへ強制リダイレクト
    context "未ログイン" do
      it "ログインページにリダイレクトする" do
        get zone_animal_path(zone, animal)
        expect(response).to redirect_to(login_path)
      end
    end

    # StaffもAdminも詳細ページは閲覧可能
    context "ログイン済み" do
      before { sign_in(staff) }

      it "200を返す" do
        get zone_animal_path(zone, animal)
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "GET /zones/:zone_id/animals/new" do
    # 動物の新規登録はAdmin専用 — Staffはルートへリダイレクト
    context "Staffがアクセス" do
      before { sign_in(staff) }

      it "ルートにリダイレクトする" do
        get new_zone_animal_path(zone)
        expect(response).to redirect_to(root_path)
      end
    end

    context "Adminがアクセス" do
      before { sign_in(admin) }

      it "200を返す" do
        get new_zone_animal_path(zone)
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "POST /zones/:zone_id/animals" do
    let(:valid_params) { { animal: { species: "インコ", gender: "unknown" } } }

    # 動物の作成はAdmin専用 — Staffはルートへリダイレクト
    context "Staffが投稿" do
      before { sign_in(staff) }

      it "ルートにリダイレクトする" do
        post zone_animals_path(zone), params: valid_params
        expect(response).to redirect_to(root_path)
      end
    end

    # Adminは動物を作成後に詳細ページへリダイレクト
    context "Adminが投稿" do
      before { sign_in(admin) }

      it "動物を作成してリダイレクトする" do
        post zone_animals_path(zone), params: valid_params
        expect(response).to redirect_to(zone_animal_path(zone, Animal.last))
      end
    end
  end

  describe "DELETE /zones/:zone_id/animals/:id" do
    let(:animal) { create(:animal, zone: zone) }

    # 削除（論理削除）はAdmin専用 — Staffはルートへリダイレクト
    context "Staffが削除しようとする" do
      before { sign_in(staff) }

      it "ルートにリダイレクトする" do
        delete zone_animal_path(zone, animal)
        expect(response).to redirect_to(root_path)
      end
    end

    # Adminが削除するとactive=falseになり館ページへリダイレクト（実際のDELETEは行わない）
    context "Adminが削除" do
      before { sign_in(admin) }

      it "論理削除してゾーンページにリダイレクトする" do
        delete zone_animal_path(zone, animal)
        expect(response).to redirect_to(zone_path(zone))
        expect(animal.reload.active).to be false
      end
    end
  end
end
