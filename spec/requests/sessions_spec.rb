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

    # user_idを消すだけではセッションIDが再利用される
    # ログイン時のreset_sessionと対称にして、値の消し忘れが起きない構造にする
    it "セッションを完全に破棄する" do
      # session.idはRack::Session::SessionIdオブジェクトを返す
      # このクラスは==を定義しておらずオブジェクト同一性で比較されるため、
      # 値を比べるには必ず文字列化する（そのまま比較すると常にパスする無意味なテストになる）
      session_id_before = session.id.to_s

      delete logout_path

      expect(session_id_before).to be_present
      expect(session.id.to_s).not_to eq(session_id_before)
    end
  end

  # ブルートフォース攻撃対策 — 同一メールアドレスへの試行を10回/3分に制限する
  describe "ログイン試行の制限" do
    let(:user) { create(:user, password: "password123") }

    it "同一メールアドレスへの試行が上限を超えるとブロックされる" do
      10.times do
        post login_path, params: { email: user.email, password: "wrongpassword" }
      end

      # 11回目は正しいパスワードでもブロックされる
      post login_path, params: { email: user.email, password: "password123" }

      expect(response).to redirect_to(login_path)
      expect(flash[:alert]).to eq("로그인 시도가 너무 많습니다. 잠시 후 다시 시도해주세요.")
      expect(session[:user_id]).to be_nil
    end

    # by: がIPではなくメールアドレス基準であることの確認
    # 同一Wi-Fi（NAT）配下の他の職員が巻き込まれないことを保証する
    it "別のメールアドレスは影響を受けない" do
      11.times do
        post login_path, params: { email: user.email, password: "wrongpassword" }
      end

      other_user = create(:user, password: "password123")
      post login_path, params: { email: other_user.email, password: "password123" }

      expect(response).to redirect_to(root_path)
      expect(session[:user_id]).to eq(other_user.id)
    end
  end

  describe "未ログインのアクセス制限" do
    it "保護されたページはログインページにリダイレクトする" do
      get root_path
      expect(response).to redirect_to(login_path)
    end
  end
end
