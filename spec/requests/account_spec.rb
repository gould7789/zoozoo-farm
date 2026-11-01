# AccountsController — 인증 제어와 프로필 표시
require "rails_helper"

RSpec.describe "Account", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:staff) { create(:user) }

  describe "GET /account" do
    context "비로그인" do
      it "로그인 화면으로 보낸다" do
        get account_path
        expect(response).to redirect_to(login_path)
      end
    end

    context "Staff 가 접근" do
      before { sign_in(staff) }

      it "200을 반환한다" do
        get account_path
        expect(response).to have_http_status(:ok)
      end
    end

    context "Admin 이 접근" do
      before { sign_in(admin) }

      it "200을 반환한다" do
        get account_path
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
