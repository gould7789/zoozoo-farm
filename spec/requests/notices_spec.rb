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

  describe "GET /notices/:id" do
    let(:notice) { create(:notice, created_by: other, title: "히터 점검", content: "<div>본문 전문</div>") }

    context "未ログイン" do
      before { get notice_path(notice) }
      it_behaves_like "ログインが必要"
    end

    # 閲覧は全員に開く。編集・削除だけが本人（とAdmin）に限られる
    context "他人のお知らせでも読める" do
      before { sign_in(staff); get notice_path(notice) }

      it { expect(response).to have_http_status(:ok) }

      it "本文の全文を出す" do
        expect(response.body).to include("본문 전문")
      end
    end
  end

  describe "GET /notices （カテゴリ絞り込み）" do
    before do
      create(:notice, created_by: staff, category: :parrot,  title: "앵무새관 공지")
      create(:notice, created_by: staff, category: :reptile, title: "파충류관 공지")
      sign_in(staff)
    end

    it "categoryを渡すとそのカテゴリだけ出す" do
      get notices_path(category: "parrot")
      expect(response.body).to include("앵무새관 공지")
      expect(response.body).not_to include("파충류관 공지")
    end

    it "categoryが無ければ全件出す" do
      get notices_path
      expect(response.body).to include("앵무새관 공지")
      expect(response.body).to include("파충류관 공지")
    end

    # enumに無い値を渡すとArgumentErrorでクラッシュする。
    # URLは手で書き換えられるので、知らない値は全件扱いにする
    it "知らないcategoryは全件扱いにする" do
      get notices_path(category: "nonsense")
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("앵무새관 공지")
    end
  end

  describe "GET /notices （N+1）" do
    def query_count
      count = 0
      sub = ActiveSupport::Notifications.subscribe("sql.active_record") do |_, _, _, _, payload|
        count += 1 unless payload[:name].to_s =~ /SCHEMA|TRANSACTION/
      end
      begin
        yield
      ensure
        ActiveSupport::Notifications.unsubscribe(sub)
      end
      count
    end

    def notice_with_photo
      blob = ActiveStorage::Blob.create_and_upload!(
        io: Rails.root.join("spec/fixtures/files/animal.jpg").open,
        filename: "a.jpg", content_type: "image/jpeg"
      )
      create(:notice, created_by: staff, content: ActionText::Content.new.append_attachables(blob))
    end

    it "お知らせが増えてもクエリ数が増えない" do
      sign_in(staff)
      notice_with_photo
      few = query_count { get notices_path }

      3.times { notice_with_photo }
      many = query_count { get notices_path }

      expect(many).to eq(few)
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
    let(:valid_params) { { notice: { category: "general", title: "テスト題名", content: "<div>テストお知らせ</div>" } } }

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

      it "本文がリッチテキストとして保存される" do
        post notices_path, params: valid_params
        expect(Notice.last.content.to_s).to include("テストお知らせ")
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
    let(:valid_params) { { notice: { title: "更新された題名", content: "<div>更新されたお知らせ</div>" } } }

    context "本人が更新" do
      let(:notice) { create(:notice, created_by: staff) }
      before { sign_in(staff) }

      it "お知らせを更新して一覧ページにリダイレクトする" do
        patch notice_path(notice), params: valid_params
        expect(response).to redirect_to(notices_path)
        expect(notice.reload.content.to_s).to include("更新されたお知らせ")
      end

      it "題名だけを変えても反映される" do
        patch notice_path(notice), params: { notice: { title: "바뀐 제목" } }
        expect(notice.reload.title).to eq("바뀐 제목")
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
