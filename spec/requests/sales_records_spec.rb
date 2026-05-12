# SalesRecordsControllerのリクエストテスト — Admin専用アクセス制御を中心に検証する
require "rails_helper"

RSpec.describe "SalesRecords", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:staff) { create(:user) }

  describe "GET /sales_records" do
    context "未ログイン" do
      before { get sales_path }
      it_behaves_like "ログインが必要"
    end

    context "Staffがアクセス" do
      before { sign_in(staff); get sales_path }
      it_behaves_like "アクセス拒否"
    end

    context "Adminがアクセス" do
      before { sign_in(admin); get sales_path }
      it { expect(response).to have_http_status(:ok) }
    end
  end

  describe "GET /sales_records/new" do
    context "未ログイン" do
      before { get new_sale_path }
      it_behaves_like "ログインが必要"
    end

    context "Staffがアクセス" do
      before { sign_in(staff); get new_sale_path }
      it_behaves_like "アクセス拒否"
    end

    context "Adminがアクセス" do
      before { sign_in(admin); get new_sale_path }
      it { expect(response).to have_http_status(:ok) }
    end
  end

  describe "POST /sales_records" do
    let(:valid_params) do
      { sales_record: { sold_on: Date.today, source: "vending_1", amount: 5000 } }
    end

    context "未ログイン" do
      before { post sales_path, params: valid_params }
      it_behaves_like "ログインが必要"
    end

    context "Staffが作成しようとする" do
      before { sign_in(staff); post sales_path, params: valid_params }
      it_behaves_like "アクセス拒否"
    end

    context "Adminが作成" do
      before { sign_in(admin) }

      it "created_byが自分のIDで保存されて一覧ページにリダイレクトする" do
        post sales_path, params: valid_params
        expect(response).to redirect_to(sales_path)
        expect(SalesRecord.last.created_by).to eq(admin)
      end
    end
  end

  describe "GET /sales_records/:id/edit" do
    let(:sales_record) { create(:sales_record, created_by: admin) }

    context "Staffがアクセス" do
      before { sign_in(staff); get edit_sale_path(sales_record) }
      it_behaves_like "アクセス拒否"
    end

    context "Adminがアクセス" do
      before { sign_in(admin); get edit_sale_path(sales_record) }
      it { expect(response).to have_http_status(:ok) }
    end
  end

  describe "PATCH /sales_records/:id" do
    let(:sales_record) { create(:sales_record, created_by: admin) }
    let(:valid_params) { { sales_record: { amount: 9000 } } }

    context "Staffが更新しようとする" do
      before { sign_in(staff); patch sale_path(sales_record), params: valid_params }
      it_behaves_like "アクセス拒否"
    end

    context "Adminが更新" do
      before { sign_in(admin) }

      it "売上記録を更新して一覧ページにリダイレクトする" do
        patch sale_path(sales_record), params: valid_params
        expect(response).to redirect_to(sales_path)
        expect(sales_record.reload.amount).to eq(9000)
      end
    end
  end

  describe "DELETE /sales_records/:id" do
    let(:sales_record) { create(:sales_record, created_by: admin) }

    context "Staffが削除しようとする" do
      before { sign_in(staff); delete sale_path(sales_record) }
      it_behaves_like "アクセス拒否"
    end

    context "Adminが削除" do
      before { sign_in(admin) }

      it "売上記録を削除して一覧ページにリダイレクトする" do
        delete sale_path(sales_record)
        expect(response).to redirect_to(sales_path)
        expect { sales_record.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
