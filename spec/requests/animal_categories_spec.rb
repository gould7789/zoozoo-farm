# AnimalCategoriesController — 인증·권한 제어와 turbo_stream 응답
require "rails_helper"

RSpec.describe "AnimalCategories", type: :request do
  let(:zone)  { create(:zone) }
  let(:admin) { create(:user, :admin) }
  let(:staff) { create(:user) }

  describe "POST /zones/:zone_id/animal_categories" do
    context "비로그인" do
      it "로그인 화면으로 보낸다" do
        post zone_animal_categories_path(zone), params: { animal_category: { name: "알파카" } }
        expect(response).to redirect_to(login_path)
      end
    end

    context "Staff 가 접근" do
      before { sign_in(staff) }

      it "권한이 없어 루트로 보낸다" do
        post zone_animal_categories_path(zone), params: { animal_category: { name: "알파카" } }
        expect(response).to redirect_to(root_path)
      end
    end

    context "Admin 이 접근" do
      before { sign_in(admin) }

      it "카테고리를 생성하고 관 페이지로 리다이렉트한다" do
        post zone_animal_categories_path(zone), params: { animal_category: { name: "알파카" } }
        expect(response).to redirect_to(zone_path(zone))
        expect(AnimalCategory.count).to eq(1)
      end

      it "이름이 없으면 관 페이지로 리다이렉트하고 alert를 표시한다" do
        post zone_animal_categories_path(zone), params: { animal_category: { name: "" } }
        expect(response).to redirect_to(zone_path(zone))
        expect(AnimalCategory.count).to eq(0)
      end

      # 추가한 카테고리가 아코디언에도 나타나야 한다
      it "아코디언도 함께 갱신한다" do
        post zone_animal_categories_path(zone),
             headers: { "Accept" => "text/vnd.turbo-stream.html" },
             params: { animal_category: { name: "알파카" } }

        expect(response.body).to include('target="category_accordion"')
        expect(response.body).to include("알파카")
      end
    end
  end

  describe "PATCH /zones/:zone_id/animal_categories/:id" do
    let!(:category) { create(:animal_category, zone: zone, name: "알파카") }

    context "Admin 이 접근" do
      before { sign_in(admin) }

      it "turbo_stream 요청 시 카테고리 이름을 수정하고 200을 반환한다" do
        patch zone_animal_category_path(zone, category),
              headers: { "Accept" => "text/vnd.turbo-stream.html" },
              params: { animal_category: { name: "낙타" } }
        expect(response).to have_http_status(:ok)
        expect(category.reload.name).to eq("낙타")
      end

      it "html 요청 시 카테고리 이름을 수정하고 관 페이지로 리다이렉트한다" do
        patch zone_animal_category_path(zone, category),
              params: { animal_category: { name: "낙타" } }
        expect(response).to redirect_to(zone_path(zone))
        expect(category.reload.name).to eq("낙타")
      end

      it "이름이 비어있으면 turbo_stream으로 편집 모드 행을 반환한다" do
        patch zone_animal_category_path(zone, category),
              headers: { "Accept" => "text/vnd.turbo-stream.html" },
              params: { animal_category: { name: "" } }
        expect(response).to have_http_status(:ok)
        expect(response.content_type).to include("text/vnd.turbo-stream.html")
      end

      # update 는 innerHTML 만 갈아끼워 partial 의 루트 div 가 이중이 된다 —
      # px-6 과 py-3.5 가 겹쳐 행이 들여쓰기되고 세로로도 두꺼워진다
      it "행을 중첩시키지 않고 replace 로 갈아끼운다" do
        patch zone_animal_category_path(zone, category),
              headers: { "Accept" => "text/vnd.turbo-stream.html" },
              params: { animal_category: { name: "낙타" } }

        row_stream = response.body[/<turbo-stream[^>]*target="category_row_#{category.id}"[^>]*>/]
        expect(row_stream).to be_present
        expect(row_stream).to include('action="replace"')
      end

      # 검증 에러 때도 같은 중첩이 나므로 양쪽 경로를 본다
      it "이름이 비어 있을 때도 replace 로 갈아끼운다" do
        patch zone_animal_category_path(zone, category),
              headers: { "Accept" => "text/vnd.turbo-stream.html" },
              params: { animal_category: { name: "" } }

        row_stream = response.body[/<turbo-stream[^>]*target="category_row_#{category.id}"[^>]*>/]
        expect(row_stream).to be_present
        expect(row_stream).to include('action="replace"')
      end

      # 모달 뒤의 아코디언에도 새 이름이 반영돼야 한다
      it "아코디언도 함께 갱신한다" do
        patch zone_animal_category_path(zone, category),
              headers: { "Accept" => "text/vnd.turbo-stream.html" },
              params: { animal_category: { name: "낙타" } }

        expect(response.body).to include('target="category_accordion"')
        expect(response.body).to include("낙타")
      end
    end
  end

  describe "PATCH /zones/:zone_id/animal_categories/:id/toggle" do
    let!(:category) { create(:animal_category, zone: zone, hidden: false) }

    context "비로그인" do
      it "로그인 화면으로 보낸다" do
        patch toggle_zone_animal_category_path(zone, category)
        expect(response).to redirect_to(login_path)
      end
    end

    context "Staff 가 접근" do
      before { sign_in(staff) }

      it "권한이 없어 루트로 보낸다" do
        patch toggle_zone_animal_category_path(zone, category)
        expect(response).to redirect_to(root_path)
      end
    end

    context "Admin 이 접근" do
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

    context "비로그인" do
      it "로그인 화면으로 보낸다" do
        delete zone_animal_category_path(zone, category)
        expect(response).to redirect_to(login_path)
      end
    end

    context "Staff 가 접근" do
      before { sign_in(staff) }

      it "권한이 없어 루트로 보낸다" do
        delete zone_animal_category_path(zone, category)
        expect(response).to redirect_to(root_path)
      end
    end

    context "Admin 이 접근" do
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
