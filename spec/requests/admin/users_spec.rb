# Admin::UsersControllerのリクエストテスト — Admin専用アクセス制御を中心に検証する
require "rails_helper"

RSpec.describe "Admin::Users", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:staff) { create(:user) }           # デフォルトはstaffロール

  describe "GET /admin/users" do
    # 未ログインはログインページへ強制リダイレクト
    context "未ログイン" do
      it "ログインページにリダイレクトする" do
        get admin_users_path
        expect(response).to redirect_to(login_path)
      end
    end

    # StaffはAdmin専用ページにアクセス不可
    context "Staffがアクセス" do
      before { sign_in(staff) }

      it "ルートにリダイレクトする" do
        get admin_users_path
        expect(response).to redirect_to(root_path)
      end
    end

    # Adminはユーザー一覧を閲覧可能
    context "Adminがアクセス" do
      before { sign_in(admin) }

      it "200を返す" do
        get admin_users_path
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "GET /admin/users/new" do
    # 未ログインはログインページへ強制リダイレクト
    context "未ログイン" do
      it "ログインページにリダイレクトする" do
        get new_admin_user_path
        expect(response).to redirect_to(login_path)
      end
    end

    # StaffはAdmin専用ページにアクセス不可
    context "Staffがアクセス" do
      before { sign_in(staff) }

      it "ルートにリダイレクトする" do
        get new_admin_user_path
        expect(response).to redirect_to(root_path)
      end
    end

    # Adminは新規作成フォームにアクセス可能
    context "Adminがアクセス" do
      before { sign_in(admin) }

      it "200を返す" do
        get new_admin_user_path
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "POST /admin/users" do
    let(:valid_params) do
      { user: { name: "홍길동", email: "hong@example.com", password: "password123", role: "staff" } }
    end

    # 未ログインはログインページへ強制リダイレクト
    context "未ログイン" do
      it "ログインページにリダイレクトする" do
        post admin_users_path, params: valid_params
        expect(response).to redirect_to(login_path)
      end
    end

    # StaffはAdmin専用ページにアクセス不可
    context "Staffが作成しようとする" do
      before { sign_in(staff) }

      it "ルートにリダイレクトする" do
        post admin_users_path, params: valid_params
        expect(response).to redirect_to(root_path)
      end
    end

    # AdminはStaffアカウントを作成可能
    context "Adminが作成" do
      before { sign_in(admin) }

      it "ユーザーを作成してユーザー一覧にリダイレクトする" do
        post admin_users_path, params: valid_params
        expect(response).to redirect_to(admin_users_path)
        expect(User.find_by(email: "hong@example.com")).to be_present
      end
    end
  end

  describe "GET /admin/users/:id/edit" do
    let(:target_user) { create(:user) }

    # 未ログインはログインページへ強制リダイレクト
    context "未ログイン" do
      it "ログインページにリダイレクトする" do
        get edit_admin_user_path(target_user)
        expect(response).to redirect_to(login_path)
      end
    end

    # StaffはAdmin専用ページにアクセス不可
    context "Staffがアクセス" do
      before { sign_in(staff) }

      it "ルートにリダイレクトする" do
        get edit_admin_user_path(target_user)
        expect(response).to redirect_to(root_path)
      end
    end

    # Adminは編集フォームにアクセス可能
    context "Adminがアクセス" do
      before { sign_in(admin) }

      it "200を返す" do
        get edit_admin_user_path(target_user)
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "PATCH /admin/users/:id" do
    let(:target_user) { create(:user) }

    # StaffはAdmin専用ページにアクセス不可
    context "Staffが更新しようとする" do
      before { sign_in(staff) }

      it "ルートにリダイレクトする" do
        patch admin_user_path(target_user), params: { user: { name: "변경" } }
        expect(response).to redirect_to(root_path)
      end
    end

    # Adminはユーザー情報を更新可能
    context "Adminが更新" do
      before { sign_in(admin) }

      it "ユーザー情報を更新してユーザー一覧にリダイレクトする" do
        patch admin_user_path(target_user), params: { user: { name: "변경된 이름" } }
        expect(response).to redirect_to(admin_users_path)
        expect(target_user.reload.name).to eq("변경된 이름")
      end
    end

    # 退職処理 — activeをfalseに変更
    context "Adminが退職処理" do
      before { sign_in(admin) }

      it "activeをfalseにしてユーザー一覧にリダイレクトする" do
        patch admin_user_path(target_user), params: { user: { active: false } }
        expect(response).to redirect_to(admin_users_path)
        expect(target_user.reload.active).to be false
      end
    end
  end
end
