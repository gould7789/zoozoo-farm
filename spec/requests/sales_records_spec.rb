# SalesRecordsControllerのリクエストテスト — Admin専用アクセス制御を中心に検証する
require "rails_helper"

RSpec.describe "SalesRecords", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:staff) { create(:user) }           # デフォルトはstaffロール

  describe "GET /sales_records" do
    # 未ログインはログインページへ強制リダイレクト
    context "未ログイン" do
      it "ログインページにリダイレクトする" do
        get sales_records_path
        expect(response).to redirect_to(login_path)
      end
    end

    # StaffはAdmin専用ページにアクセス不可
    context "Staffがアクセス" do
      before { sign_in(staff) }

      it "ルートにリダイレクトする" do
        get sales_records_path
        expect(response).to redirect_to(root_path)
      end
    end

    # Adminは一覧閲覧可能
    context "Adminがアクセス" do
      before { sign_in(admin) }

      it "200を返す" do
        get sales_records_path
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "GET /sales_records/new" do
    # 未ログインはログインページへ強制リダイレクト
    context "未ログイン" do
      it "ログインページにリダイレクトする" do
        get new_sales_record_path
        expect(response).to redirect_to(login_path)
      end
    end

    # StaffはAdmin専用ページにアクセス不可
    context "Staffがアクセス" do
      before { sign_in(staff) }

      it "ルートにリダイレクトする" do
        get new_sales_record_path
        expect(response).to redirect_to(root_path)
      end
    end

    # Adminは新規作成フォームにアクセス可能
    context "Adminがアクセス" do
      before { sign_in(admin) }

      it "200を返す" do
        get new_sales_record_path
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "POST /sales_records" do
    let(:valid_params) do
      { sales_record: { sold_on: Date.today, source: "vending_1", amount: 5000 } }
    end

    # 未ログインはログインページへ強制リダイレクト
    context "未ログイン" do
      it "ログインページにリダイレクトする" do
        post sales_records_path, params: valid_params
        expect(response).to redirect_to(login_path)
      end
    end

    # StaffはAdmin専用ページにアクセス不可
    context "Staffが作成しようとする" do
      before { sign_in(staff) }

      it "ルートにリダイレクトする" do
        post sales_records_path, params: valid_params
        expect(response).to redirect_to(root_path)
      end
    end

    # Adminが作成すると自分のcreated_byで保存される
    context "Adminが作成" do
      before { sign_in(admin) }

      it "created_byが自分のIDで保存されて一覧ページにリダイレクトする" do
        post sales_records_path, params: valid_params
        expect(response).to redirect_to(sales_records_path)
        expect(SalesRecord.last.created_by).to eq(admin)
      end
    end
  end

  describe "GET /sales_records/:id/edit" do
    let(:sales_record) { create(:sales_record, created_by: admin) }

    # StaffはAdmin専用ページにアクセス不可
    context "Staffがアクセス" do
      before { sign_in(staff) }

      it "ルートにリダイレクトする" do
        get edit_sales_record_path(sales_record)
        expect(response).to redirect_to(root_path)
      end
    end

    # Adminは編集フォームにアクセス可能
    context "Adminがアクセス" do
      before { sign_in(admin) }

      it "200を返す" do
        get edit_sales_record_path(sales_record)
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "PATCH /sales_records/:id" do
    let(:sales_record) { create(:sales_record, created_by: admin) }
    let(:valid_params) { { sales_record: { amount: 9000 } } }

    # StaffはAdmin専用ページにアクセス不可
    context "Staffが更新しようとする" do
      before { sign_in(staff) }

      it "ルートにリダイレクトする" do
        patch sales_record_path(sales_record), params: valid_params
        expect(response).to redirect_to(root_path)
      end
    end

    # Adminは更新可能
    context "Adminが更新" do
      before { sign_in(admin) }

      it "売上記録を更新して一覧ページにリダイレクトする" do
        patch sales_record_path(sales_record), params: valid_params
        expect(response).to redirect_to(sales_records_path)
        expect(sales_record.reload.amount).to eq(9000)
      end
    end
  end

  describe "DELETE /sales_records/:id" do
    let(:sales_record) { create(:sales_record, created_by: admin) }

    # StaffはAdmin専用ページにアクセス不可
    context "Staffが削除しようとする" do
      before { sign_in(staff) }

      it "ルートにリダイレクトする" do
        delete sales_record_path(sales_record)
        expect(response).to redirect_to(root_path)
      end
    end

    # Adminは削除可能
    context "Adminが削除" do
      before { sign_in(admin) }

      it "売上記録を削除して一覧ページにリダイレクトする" do
        delete sales_record_path(sales_record)
        expect(response).to redirect_to(sales_records_path)
        expect { sales_record.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
