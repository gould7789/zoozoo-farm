# Admin::UsersControllerのリクエストテスト — Admin専用アクセス制御を中心に検証する
require "rails_helper"

RSpec.describe "Admin::Users", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:staff) { create(:user) }           # デフォルトはstaffロール

  describe "GET /admin/users" do
    # 未ログインはログインページへ強制リダイレクト
    context "未ログイン" do
      it "ログインページにリダイレクトする" do
        get admin_members_path
        expect(response).to redirect_to(login_path)
      end
    end

    # StaffはAdmin専用ページにアクセス不可
    context "Staffがアクセス" do
      before { sign_in(staff) }

      it "ルートにリダイレクトする" do
        get admin_members_path
        expect(response).to redirect_to(root_path)
      end
    end

    # Adminはユーザー一覧を閲覧可能
    context "Adminがアクセス" do
      before { sign_in(admin) }

      it "200を返す" do
        get admin_members_path
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "GET /admin/users/new" do
    # 未ログインはログインページへ強制リダイレクト
    context "未ログイン" do
      it "ログインページにリダイレクトする" do
        get new_admin_member_path
        expect(response).to redirect_to(login_path)
      end
    end

    # StaffはAdmin専用ページにアクセス不可
    context "Staffがアクセス" do
      before { sign_in(staff) }

      it "ルートにリダイレクトする" do
        get new_admin_member_path
        expect(response).to redirect_to(root_path)
      end
    end

    # Adminは新規作成フォームにアクセス可能
    context "Adminがアクセス" do
      before { sign_in(admin) }

      it "200を返す" do
        get new_admin_member_path
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
        post admin_members_path, params: valid_params
        expect(response).to redirect_to(login_path)
      end
    end

    # StaffはAdmin専用ページにアクセス不可
    context "Staffが作成しようとする" do
      before { sign_in(staff) }

      it "ルートにリダイレクトする" do
        post admin_members_path, params: valid_params
        expect(response).to redirect_to(root_path)
      end
    end

    # AdminはStaffアカウントを作成可能
    context "Adminが作成" do
      before { sign_in(admin) }

      it "ユーザーを作成してユーザー一覧にリダイレクトする" do
        post admin_members_path, params: valid_params
        expect(response).to redirect_to(admin_members_path)
        expect(User.find_by(email: "hong@example.com")).to be_present
      end
    end
  end

  describe "GET /admin/users/:id/edit" do
    let(:target_user) { create(:user) }

    # 未ログインはログインページへ強制リダイレクト
    context "未ログイン" do
      it "ログインページにリダイレクトする" do
        get edit_admin_member_path(target_user)
        expect(response).to redirect_to(login_path)
      end
    end

    # StaffはAdmin専用ページにアクセス不可
    context "Staffがアクセス" do
      before { sign_in(staff) }

      it "ルートにリダイレクトする" do
        get edit_admin_member_path(target_user)
        expect(response).to redirect_to(root_path)
      end
    end

    # Adminは編集フォームにアクセス可能
    context "Adminがアクセス" do
      before { sign_in(admin) }

      it "200を返す" do
        get edit_admin_member_path(target_user)
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
        patch admin_member_path(target_user), params: { user: { name: "변경" } }
        expect(response).to redirect_to(root_path)
      end
    end

    # Adminはユーザー情報を更新可能
    context "Adminが更新" do
      before { sign_in(admin) }

      it "ユーザー情報を更新してユーザー一覧にリダイレクトする" do
        patch admin_member_path(target_user), params: { user: { name: "변경된 이름" } }
        expect(response).to redirect_to(admin_members_path)
        expect(target_user.reload.name).to eq("변경된 이름")
      end
    end

    # 退職処理 — activeをfalseに変更
    context "Adminが退職処理" do
      before { sign_in(admin) }

      it "activeをfalseにしてユーザー一覧にリダイレクトする" do
        patch admin_member_path(target_user), params: { user: { active: false } }
        expect(response).to redirect_to(admin_members_path)
        expect(target_user.reload.active).to be false
      end
    end

    # ロックアウト防止 — 自分自身の役割は変更させない
    context "Adminが自分自身のroleを変更しようとした場合" do
      before { sign_in(admin) }

      it "roleがadminのまま変わらない" do
        patch admin_member_path(admin), params: { user: { role: "staff" } }
        expect(admin.reload.role).to eq("admin")
      end
    end

    # ロックアウト防止 — 自分自身を退職扱いにすると再ログインできなくなる
    context "Adminが自分自身をactive=falseにしようとした場合" do
      before { sign_in(admin) }

      it "activeがtrueのまま変わらない" do
        patch admin_member_path(admin), params: { user: { active: false } }
        expect(admin.reload.active).to be true
      end
    end
  end

  describe "DELETE /admin/members/:id" do
    let(:target_user) { create(:user) }

    # Adminが他のユーザーを削除
    context "Adminが他のユーザーを削除" do
      before { sign_in(admin) }

      it "削除に成功しadmin_members_pathにリダイレクトする" do
        delete admin_member_path(target_user)
        expect(response).to redirect_to(admin_members_path)
        expect(User.exists?(target_user.id)).to be false
      end
    end

    # Adminが自分自身を削除しようとした場合
    context "Adminが自分自身を削除しようとした場合" do
      before { sign_in(admin) }

      it "削除できずadmin_members_pathにリダイレクトする" do
        delete admin_member_path(admin)
        expect(response).to redirect_to(admin_members_path)
        expect(User.exists?(admin.id)).to be true
      end
    end

    # 記録を持つユーザーはrestrict_with_errorで物理削除が拒否される
    context "記録を持つユーザーを削除しようとした場合" do
      before { sign_in(admin) }

      it "削除されずアラートを表示する" do
        create(:notice, created_by: target_user)
        delete admin_member_path(target_user)
        expect(response).to redirect_to(admin_members_path)
        expect(User.exists?(target_user.id)).to be true
        expect(flash[:alert]).to be_present
      end
    end

    # 記録が0件のユーザー（一日バイト・誤作成アカウント）は削除できる
    context "記録を持たないユーザーを削除する場合" do
      before { sign_in(admin) }

      it "削除される" do
        delete admin_member_path(target_user)
        expect(response).to redirect_to(admin_members_path)
        expect(User.exists?(target_user.id)).to be false
        expect(flash[:notice]).to be_present
      end
    end

    # Staffがアクセスした場合
    context "Staffがアクセスした場合" do
      before { sign_in(staff) }

      it "ルートにリダイレクトする（権限なし）" do
        delete admin_member_path(target_user)
        expect(response).to redirect_to(root_path)
        expect(User.exists?(target_user.id)).to be true
      end
    end
  end
end
