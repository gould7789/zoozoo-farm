# Admin::UsersController — Admin 전용 접근 제어와 삭제 분기
require "rails_helper"

RSpec.describe "Admin::Users", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:staff) { create(:user) }           # 팩토리 기본값이 staff

  describe "GET /admin/users" do
    context "비로그인" do
      it "로그인 화면으로 보낸다" do
        get admin_members_path
        expect(response).to redirect_to(login_path)
      end
    end

    context "Staff 가 접근" do
      before { sign_in(staff) }

      it "루트로 보낸다" do
        get admin_members_path
        expect(response).to redirect_to(root_path)
      end
    end

    context "Admin 이 접근" do
      before { sign_in(admin) }

      it "200을 반환한다" do
        get admin_members_path
        expect(response).to have_http_status(:ok)
      end
    end

    # 삭제 버튼을 가르는 데 쓰는 기록 보유자 ID 집계 쿼리를 지나게 한다
    context "기록을 가진 사용자가 있는 경우" do
      before { sign_in(admin) }

      it "200을 반환한다" do
        create(:notice, created_by: staff)
        get admin_members_path
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "GET /admin/users/new" do
    context "비로그인" do
      it "로그인 화면으로 보낸다" do
        get new_admin_member_path
        expect(response).to redirect_to(login_path)
      end
    end

    context "Staff 가 접근" do
      before { sign_in(staff) }

      it "루트로 보낸다" do
        get new_admin_member_path
        expect(response).to redirect_to(root_path)
      end
    end

    context "Admin 이 접근" do
      before { sign_in(admin) }

      it "200을 반환한다" do
        get new_admin_member_path
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "POST /admin/users" do
    let(:valid_params) do
      { user: { name: "홍길동", email: "hong@example.com", password: "password123", role: "staff" } }
    end

    context "비로그인" do
      it "로그인 화면으로 보낸다" do
        post admin_members_path, params: valid_params
        expect(response).to redirect_to(login_path)
      end
    end

    context "Staff 가 작성을 시도" do
      before { sign_in(staff) }

      it "루트로 보낸다" do
        post admin_members_path, params: valid_params
        expect(response).to redirect_to(root_path)
      end
    end

    context "Admin 이 작성" do
      before { sign_in(admin) }

      it "사용자를 만들고 목록으로 보낸다" do
        post admin_members_path, params: valid_params
        expect(response).to redirect_to(admin_members_path)
        expect(User.find_by(email: "hong@example.com")).to be_present
      end
    end
  end

  describe "GET /admin/users/:id/edit" do
    let(:target_user) { create(:user) }

    context "비로그인" do
      it "로그인 화면으로 보낸다" do
        get edit_admin_member_path(target_user)
        expect(response).to redirect_to(login_path)
      end
    end

    context "Staff 가 접근" do
      before { sign_in(staff) }

      it "루트로 보낸다" do
        get edit_admin_member_path(target_user)
        expect(response).to redirect_to(root_path)
      end
    end

    context "Admin 이 접근" do
      before { sign_in(admin) }

      it "200을 반환한다" do
        get edit_admin_member_path(target_user)
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "PATCH /admin/users/:id" do
    let(:target_user) { create(:user) }

    context "Staff 가 수정을 시도" do
      before { sign_in(staff) }

      it "루트로 보낸다" do
        patch admin_member_path(target_user), params: { user: { name: "변경" } }
        expect(response).to redirect_to(root_path)
      end
    end

    context "Admin 이 수정" do
      before { sign_in(admin) }

      it "사용자 정보를 수정하고 목록으로 보낸다" do
        patch admin_member_path(target_user), params: { user: { name: "변경된 이름" } }
        expect(response).to redirect_to(admin_members_path)
        expect(target_user.reload.name).to eq("변경된 이름")
      end
    end

    context "Admin 이 퇴사 처리" do
      before { sign_in(admin) }

      it "active 를 false 로 바꾸고 목록으로 보낸다" do
        patch admin_member_path(target_user), params: { user: { active: false } }
        expect(response).to redirect_to(admin_members_path)
        expect(target_user.reload.active).to be false
      end
    end

    # 잠금 방지 — 자기 역할은 바꾸지 못하게 한다 (notes/auth.md)
    context "Admin 이 자기 role 을 바꾸려는 경우" do
      before { sign_in(admin) }

      it "role 이 admin 그대로 바뀌지 않는다" do
        patch admin_member_path(admin), params: { user: { role: "staff" } }
        expect(admin.reload.role).to eq("admin")
      end
    end

    # 잠금 방지 — 자기를 퇴사 처리하면 다시 로그인할 수 없다
    context "Admin 이 자기를 active = false 로 하려는 경우" do
      before { sign_in(admin) }

      it "active 가 true 그대로 바뀌지 않는다" do
        patch admin_member_path(admin), params: { user: { active: false } }
        expect(admin.reload.active).to be true
      end
    end
  end

  describe "DELETE /admin/members/:id" do
    let(:target_user) { create(:user) }

    context "Admin 이 다른 사용자를 삭제" do
      before { sign_in(admin) }

      it "삭제에 성공하고 admin_members_path 로 보낸다" do
        delete admin_member_path(target_user)
        expect(response).to redirect_to(admin_members_path)
        expect(User.exists?(target_user.id)).to be false
      end
    end

    context "Admin 이 자기를 지우려는 경우" do
      before { sign_in(admin) }

      it "지우지 못하고 admin_members_path 로 보낸다" do
        delete admin_member_path(admin)
        expect(response).to redirect_to(admin_members_path)
        expect(User.exists?(admin.id)).to be true
      end
    end

    # 기록을 가진 사용자는 restrict_with_error 가 물리 삭제를 거부한다
    context "기록을 가진 사용자를 지우려는 경우" do
      before { sign_in(admin) }

      it "지워지지 않고 알림을 띄운다" do
        create(:notice, created_by: target_user)
        delete admin_member_path(target_user)
        expect(response).to redirect_to(admin_members_path)
        expect(User.exists?(target_user.id)).to be true
        expect(flash[:alert]).to be_present
      end
    end

    # 기록이 0건인 사용자(하루 알바·잘못 만든 계정)는 지울 수 있다
    context "기록이 없는 사용자를 지우는 경우" do
      before { sign_in(admin) }

      it "지워진다" do
        delete admin_member_path(target_user)
        expect(response).to redirect_to(admin_members_path)
        expect(User.exists?(target_user.id)).to be false
        expect(flash[:notice]).to be_present
      end
    end

    context "Staff 가 접근한 경우" do
      before { sign_in(staff) }

      it "권한이 없어 루트로 보낸다" do
        delete admin_member_path(target_user)
        expect(response).to redirect_to(root_path)
        expect(User.exists?(target_user.id)).to be true
      end
    end
  end
end
