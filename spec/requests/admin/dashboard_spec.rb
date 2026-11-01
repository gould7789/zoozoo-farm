# Admin::DashboardController — Admin 전용 접근 제어
require "rails_helper"

RSpec.describe "Admin::Dashboard", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:staff) { create(:user) }

  describe "GET /admin/dashboard" do
    context "비로그인" do
      it "로그인 화면으로 보낸다" do
        get admin_dashboard_path
        expect(response).to redirect_to(login_path)
      end
    end

    context "Staff 가 접근" do
      before { sign_in(staff) }

      it "루트로 보낸다" do
        get admin_dashboard_path
        expect(response).to redirect_to(root_path)
      end
    end

    context "Admin 이 접근" do
      before { sign_in(admin) }

      it "200을 반환한다" do
        get admin_dashboard_path
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
