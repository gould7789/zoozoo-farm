require "rails_helper"

RSpec.describe "Sessions", type: :request do
  describe "GET /login" do
    it "ログインページを表示する" do
      get login_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /login" do
    let(:user) { create(:user, password: "password123") }

    context "正しい認証情報の場合" do
      it "ルートにリダイレクトする" do
        post login_path, params: { email: user.email, password: "password123" }
        expect(response).to redirect_to(root_path)
      end

      it "セッションにuser_idを保存する" do
        post login_path, params: { email: user.email, password: "password123" }
        expect(session[:user_id]).to eq(user.id)
      end
    end

    context "間違ったパスワードの場合" do
      it "ログインページに戻る" do
        post login_path, params: { email: user.email, password: "wrongpassword" }
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "セッションにuser_idを保存しない" do
        post login_path, params: { email: user.email, password: "wrongpassword" }
        expect(session[:user_id]).to be_nil
      end
    end

    context "非アクティブユーザーの場合" do
      let(:inactive_user) { create(:user, :inactive, password: "password123") }

      it "ログインできない" do
        post login_path, params: { email: inactive_user.email, password: "password123" }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "DELETE /logout" do
    before do
      user = create(:user, password: "password123")
      post login_path, params: { email: user.email, password: "password123" }
    end

    it "ログアウト後はログインページにリダイレクトする" do
      delete logout_path
      expect(response).to redirect_to(login_path)
    end

    it "セッションのuser_idを削除する" do
      delete logout_path
      expect(session[:user_id]).to be_nil
    end
  end

  describe "未ログインのアクセス制限" do
    it "保護されたページはログインページにリダイレクトする" do
      get root_path
      expect(response).to redirect_to(login_path)
    end
  end
end
