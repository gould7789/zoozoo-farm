# Admin::DashboardControllerのリクエストテスト — Admin専用アクセス制御を検証する
require "rails_helper"

RSpec.describe "Admin::Dashboard", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:staff) { create(:user) }

  describe "GET /admin/dashboard" do
    # 未ログインはログインページへ強制リダイレクト
    context "未ログイン" do
      it "ログインページにリダイレクトする" do
        get admin_dashboard_path
        expect(response).to redirect_to(login_path)
      end
    end

    # StaffはAdmin専用ページにアクセス不可
    context "Staffがアクセス" do
      before { sign_in(staff) }

      it "ルートにリダイレクトする" do
        get admin_dashboard_path
        expect(response).to redirect_to(root_path)
      end
    end

    # Adminは管理ハブを閲覧可能
    context "Adminがアクセス" do
      before { sign_in(admin) }

      it "200を返す" do
        get admin_dashboard_path
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
