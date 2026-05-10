# NoticesControllerのリクエストテスト — 認証・権限制御を中心に検証する
# Staff/Admin共に作成・編集・削除可能、ただし編集・削除は本人記録のみ（Adminは他者記録も操作可能）
require "rails_helper"

RSpec.describe "Notices", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:staff) { create(:user) }
  let(:other) { create(:user) }

  describe "GET /notices" do
    context "未ログイン" do
      before { get notices_path }
      it_behaves_like "ログインが必要"
    end

    context "ログイン済み" do
      before { sign_in(staff); get notices_path }
      it { expect(response).to have_http_status(:ok) }
    end
  end

  describe "GET /notices/new" do
    context "未ログイン" do
      before { get new_notice_path }
      it_behaves_like "ログインが必要"
    end

    context "ログイン済み" do
      before { sign_in(staff); get new_notice_path }
      it { expect(response).to have_http_status(:ok) }
    end
  end

  describe "POST /notices" do
    let(:valid_params) { { notice: { category: "general", body: "テストお知らせ" } } }

    context "未ログイン" do
      before { post notices_path, params: valid_params }
      it_behaves_like "ログインが必要"
    end

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
    context "本人のお知らせ" do
      let(:notice) { create(:notice, created_by: staff) }
      before { sign_in(staff); get edit_notice_path(notice) }
      it { expect(response).to have_http_status(:ok) }
    end

    context "他人のお知らせ" do
      let(:notice) { create(:notice, created_by: other) }
      before { sign_in(staff); get edit_notice_path(notice) }
      it_behaves_like "アクセス拒否"
    end

    context "Adminが他人のお知らせにアクセス" do
      let(:notice) { create(:notice, created_by: staff) }
      before { sign_in(admin); get edit_notice_path(notice) }
      it { expect(response).to have_http_status(:ok) }
    end
  end

  describe "PATCH /notices/:id" do
    let(:valid_params) { { notice: { body: "更新されたお知らせ" } } }

    context "本人が更新" do
      let(:notice) { create(:notice, created_by: staff) }
      before { sign_in(staff) }

      it "お知らせを更新して一覧ページにリダイレクトする" do
        patch notice_path(notice), params: valid_params
        expect(response).to redirect_to(notices_path)
        expect(notice.reload.body).to eq("更新されたお知らせ")
      end
    end

    context "他人のお知らせを更新しようとする" do
      let(:notice) { create(:notice, created_by: other) }
      before { sign_in(staff); patch notice_path(notice), params: valid_params }
      it_behaves_like "アクセス拒否"
    end
  end

  describe "DELETE /notices/:id" do
    context "本人が削除" do
      let(:notice) { create(:notice, created_by: staff) }
      before { sign_in(staff) }

      it "お知らせを削除して一覧ページにリダイレクトする" do
        delete notice_path(notice)
        expect(response).to redirect_to(notices_path)
        expect { notice.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "他人のお知らせを削除しようとする" do
      let(:notice) { create(:notice, created_by: other) }
      before { sign_in(staff); delete notice_path(notice) }
      it_behaves_like "アクセス拒否"
    end

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
