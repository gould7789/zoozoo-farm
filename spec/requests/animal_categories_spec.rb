# AnimalCategoriesControllerのリクエストテスト — 認証・権限制御を中心に検証する
require "rails_helper"

RSpec.describe "AnimalCategories", type: :request do
  let(:zone)  { create(:zone) }
  let(:admin) { create(:user, :admin) }
  let(:staff) { create(:user) }

  describe "POST /zones/:zone_id/animal_categories" do
    context "未ログイン" do
      it "ログインページにリダイレクトする" do
        post zone_animal_categories_path(zone), params: { animal_category: { name: "アルパカ" } }
        expect(response).to redirect_to(login_path)
      end
    end

    context "Staffがアクセス" do
      before { sign_in(staff) }

      it "ルートにリダイレクトする（権限なし）" do
        post zone_animal_categories_path(zone), params: { animal_category: { name: "アルパカ" } }
        expect(response).to redirect_to(root_path)
      end
    end

    context "Adminがアクセス" do
      before { sign_in(admin) }

      it "카테고리를 생성하고 관 페이지로 리다이렉트한다" do
        post zone_animal_categories_path(zone), params: { animal_category: { name: "アルパカ" } }
        expect(response).to redirect_to(zone_path(zone))
        expect(AnimalCategory.count).to eq(1)
      end

      it "이름이 없으면 관 페이지로 리다이렉트하고 alert를 표시한다" do
        post zone_animal_categories_path(zone), params: { animal_category: { name: "" } }
        expect(response).to redirect_to(zone_path(zone))
        expect(AnimalCategory.count).to eq(0)
      end
    end
  end

  describe "PATCH /zones/:zone_id/animal_categories/:id" do
    let!(:category) { create(:animal_category, zone: zone, name: "アルパカ") }

    context "Adminがアクセス" do
      before { sign_in(admin) }

      it "turbo_stream 요청 시 카테고리 이름을 수정하고 200을 반환한다" do
        patch zone_animal_category_path(zone, category),
              headers: { "Accept" => "text/vnd.turbo-stream.html" },
              params: { animal_category: { name: "ラクダ" } }
        expect(response).to have_http_status(:ok)
        expect(category.reload.name).to eq("ラクダ")
      end

      it "html 요청 시 카테고리 이름을 수정하고 관 페이지로 리다이렉트한다" do
        patch zone_animal_category_path(zone, category),
              params: { animal_category: { name: "ラクダ" } }
        expect(response).to redirect_to(zone_path(zone))
        expect(category.reload.name).to eq("ラクダ")
      end

      it "이름이 비어있으면 turbo_stream으로 편집 모드 행을 반환한다" do
        patch zone_animal_category_path(zone, category),
              headers: { "Accept" => "text/vnd.turbo-stream.html" },
              params: { animal_category: { name: "" } }
        expect(response).to have_http_status(:ok)
        expect(response.content_type).to include("text/vnd.turbo-stream.html")
      end
    end
  end

  describe "PATCH /zones/:zone_id/animal_categories/:id/toggle" do
    let!(:category) { create(:animal_category, zone: zone, hidden: false) }

    context "未ログイン" do
      it "ログインページにリダイレクトする" do
        patch toggle_zone_animal_category_path(zone, category)
        expect(response).to redirect_to(login_path)
      end
    end

    context "Staffがアクセス" do
      before { sign_in(staff) }

      it "ルートにリダイレクトする（権限なし）" do
        patch toggle_zone_animal_category_path(zone, category)
        expect(response).to redirect_to(root_path)
      end
    end

    context "Adminがアクセス" do
      before { sign_in(admin) }

      it "hidden을 true로 토글한다" do
        patch toggle_zone_animal_category_path(zone, category)
        expect(category.reload.hidden).to be true
      end

      it "두 번 토글하면 다시 false가 된다" do
        patch toggle_zone_animal_category_path(zone, category)
        patch toggle_zone_animal_category_path(zone, category)
        expect(category.reload.hidden).to be false
      end

      it "turbo_stream 요청 시 200을 반환한다" do
        patch toggle_zone_animal_category_path(zone, category),
              headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(response).to have_http_status(:ok)
        expect(response.content_type).to include("text/vnd.turbo-stream.html")
      end

      it "html 요청 시 zone show 페이지로 리다이렉트한다" do
        patch toggle_zone_animal_category_path(zone, category)
        expect(response).to redirect_to(zone_path(zone))
      end
    end
  end

  describe "DELETE /zones/:zone_id/animal_categories/:id" do
    let!(:category) { create(:animal_category, zone: zone) }

    context "未ログイン" do
      it "ログインページにリダイレクトする" do
        delete zone_animal_category_path(zone, category)
        expect(response).to redirect_to(login_path)
      end
    end

    context "Staffがアクセス" do
      before { sign_in(staff) }

      it "ルートにリダイレクトする（権限なし）" do
        delete zone_animal_category_path(zone, category)
        expect(response).to redirect_to(root_path)
      end
    end

    context "Adminがアクセス" do
      before { sign_in(admin) }

      it "카테고리를 삭제하고 관 페이지로 리다이렉트한다" do
        delete zone_animal_category_path(zone, category)
        expect(response).to redirect_to(zone_path(zone))
        expect(AnimalCategory.find_by(id: category.id)).to be_nil
      end

      it "카테고리 삭제 후 소속 동물은 미분류로 이동된다" do
        animal = create(:animal, zone: zone, animal_category: category)
        delete zone_animal_category_path(zone, category)
        expect(animal.reload.animal_category_id).to be_nil
      end
    end
  end
end
