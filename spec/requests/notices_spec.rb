# NoticesControllerのリクエストテスト — 認証・権限制御を中心に検証する
# Staff/Admin共に作成・編集・削除可能、ただし編集・削除は本人記録のみ（Adminは他者記録も操作可能）
require "rails_helper"

RSpec.describe "Notices", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:staff) { create(:user) }           # デフォルトはstaffロール
  let(:other) { create(:user) }           # 別のStaffユーザー

  describe "GET /notices" do
    # 未ログインはログインページへ強制リダイレクト
    context "未ログイン" do
      it "ログインページにリダイレクトする" do
        get notices_path
        expect(response).to redirect_to(login_path)
      end
    end

    # Staff/Admin共に一覧閲覧可能
    context "ログイン済み" do
      before { sign_in(staff) }

      it "200を返す" do
        get notices_path
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "GET /notices/new" do
    # 未ログインはログインページへ強制リダイレクト
    context "未ログイン" do
      it "ログインページにリダイレクトする" do
        get new_notice_path
        expect(response).to redirect_to(login_path)
      end
    end

    # Staff/Admin共に新規作成フォームにアクセス可能
    context "ログイン済み" do
      before { sign_in(staff) }

      it "200を返す" do
        get new_notice_path
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "POST /notices" do
    let(:valid_params) do
      { notice: { category: "general", body: "テストお知らせ" } }
    end

    # 未ログインはログインページへ強制リダイレクト
    context "未ログイン" do
      it "ログインページにリダイレクトする" do
        post notices_path, params: valid_params
        expect(response).to redirect_to(login_path)
      end
    end

    # Staffが作成すると自分のcreated_byで保存される
    context "Staffが作成" do
      before { sign_in(staff) }

      it "created_byが自分のIDで保存されて一覧ページにリダイレクトする" do
        post notices_path, params: valid_params
        expect(response).to redirect_to(notices_path)
        expect(Notice.last.created_by).to eq(staff)
      end
    end
  end

  describe "GET /notices/:id/edit" do
    # 自分のお知らせはedit可能
    context "本人のお知らせ" do
      let(:notice) { create(:notice, created_by: staff) }
      before { sign_in(staff) }

      it "200を返す" do
        get edit_notice_path(notice)
        expect(response).to have_http_status(:ok)
      end
    end

    # 他人のお知らせはedit不可 — ルートへリダイレクト
    context "他人のお知らせ" do
      let(:notice) { create(:notice, created_by: other) }
      before { sign_in(staff) }

      it "ルートにリダイレクトする" do
        get edit_notice_path(notice)
        expect(response).to redirect_to(root_path)
      end
    end

    # Adminは他人のお知らせもedit可能
    context "Adminが他人のお知らせにアクセス" do
      let(:notice) { create(:notice, created_by: staff) }
      before { sign_in(admin) }

      it "200を返す" do
        get edit_notice_path(notice)
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "PATCH /notices/:id" do
    let(:valid_params) { { notice: { body: "更新されたお知らせ" } } }

    # 自分のお知らせは更新可能
    context "本人が更新" do
      let(:notice) { create(:notice, created_by: staff) }
      before { sign_in(staff) }

      it "お知らせを更新して一覧ページにリダイレクトする" do
        patch notice_path(notice), params: valid_params
        expect(response).to redirect_to(notices_path)
        expect(notice.reload.body).to eq("更新されたお知らせ")
      end
    end

    # 他人のお知らせは更新不可
    context "他人のお知らせを更新しようとする" do
      let(:notice) { create(:notice, created_by: other) }
      before { sign_in(staff) }

      it "ルートにリダイレクトする" do
        patch notice_path(notice), params: valid_params
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "DELETE /notices/:id" do
    # 自分のお知らせは削除可能
    context "本人が削除" do
      let(:notice) { create(:notice, created_by: staff) }
      before { sign_in(staff) }

      it "お知らせを削除して一覧ページにリダイレクトする" do
        delete notice_path(notice)
        expect(response).to redirect_to(notices_path)
        expect { notice.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    # 他人のお知らせは削除不可
    context "他人のお知らせを削除しようとする" do
      let(:notice) { create(:notice, created_by: other) }
      before { sign_in(staff) }

      it "ルートにリダイレクトする" do
        delete notice_path(notice)
        expect(response).to redirect_to(root_path)
      end
    end

    # Adminは他人のお知らせも削除可能
    context "Adminが他人のお知らせを削除" do
      let(:notice) { create(:notice, created_by: staff) }
      before { sign_in(admin) }

      it "お知らせを削除して一覧ページにリダイレクトする" do
        delete notice_path(notice)
        expect(response).to redirect_to(notices_path)
        expect { notice.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
