# ExpenseRecordsControllerのリクエストテスト — Admin専用アクセス制御を中心に検証する
require "rails_helper"

RSpec.describe "ExpenseRecords", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:staff) { create(:user) }           # デフォルトはstaffロール

  describe "GET /expense_records" do
    # 未ログインはログインページへ強制リダイレクト
    context "未ログイン" do
      it "ログインページにリダイレクトする" do
        get expense_records_path
        expect(response).to redirect_to(login_path)
      end
    end

    # StaffはAdmin専用ページにアクセス不可
    context "Staffがアクセス" do
      before { sign_in(staff) }

      it "ルートにリダイレクトする" do
        get expense_records_path
        expect(response).to redirect_to(root_path)
      end
    end

    # Adminは一覧閲覧可能
    context "Adminがアクセス" do
      before { sign_in(admin) }

      it "200を返す" do
        get expense_records_path
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "GET /expense_records/new" do
    # 未ログインはログインページへ強制リダイレクト
    context "未ログイン" do
      it "ログインページにリダイレクトする" do
        get new_expense_record_path
        expect(response).to redirect_to(login_path)
      end
    end

    # StaffはAdmin専用ページにアクセス不可
    context "Staffがアクセス" do
      before { sign_in(staff) }

      it "ルートにリダイレクトする" do
        get new_expense_record_path
        expect(response).to redirect_to(root_path)
      end
    end

    # Adminは新規作成フォームにアクセス可能
    context "Adminがアクセス" do
      before { sign_in(admin) }

      it "200を返す" do
        get new_expense_record_path
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "POST /expense_records" do
    let(:valid_params) do
      { expense_record: { spent_on: Date.today, category: "food", amount: 5000, description: "먹이 구매" } }
    end

    # 未ログインはログインページへ強制リダイレクト
    context "未ログイン" do
      it "ログインページにリダイレクトする" do
        post expense_records_path, params: valid_params
        expect(response).to redirect_to(login_path)
      end
    end

    # StaffはAdmin専用ページにアクセス不可
    context "Staffが作成しようとする" do
      before { sign_in(staff) }

      it "ルートにリダイレクトする" do
        post expense_records_path, params: valid_params
        expect(response).to redirect_to(root_path)
      end
    end

    # Adminが作成すると自分のcreated_byで保存される
    context "Adminが作成" do
      before { sign_in(admin) }

      it "created_byが自分のIDで保存されて一覧ページにリダイレクトする" do
        post expense_records_path, params: valid_params
        expect(response).to redirect_to(expense_records_path)
        expect(ExpenseRecord.last.created_by).to eq(admin)
      end
    end
  end

  describe "GET /expense_records/:id/edit" do
    let(:expense_record) { create(:expense_record, created_by: admin) }

    # StaffはAdmin専用ページにアクセス不可
    context "Staffがアクセス" do
      before { sign_in(staff) }

      it "ルートにリダイレクトする" do
        get edit_expense_record_path(expense_record)
        expect(response).to redirect_to(root_path)
      end
    end

    # Adminは編集フォームにアクセス可能
    context "Adminがアクセス" do
      before { sign_in(admin) }

      it "200を返す" do
        get edit_expense_record_path(expense_record)
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "PATCH /expense_records/:id" do
    let(:expense_record) { create(:expense_record, created_by: admin) }
    let(:valid_params) { { expense_record: { amount: 9000 } } }

    # StaffはAdmin専用ページにアクセス不可
    context "Staffが更新しようとする" do
      before { sign_in(staff) }

      it "ルートにリダイレクトする" do
        patch expense_record_path(expense_record), params: valid_params
        expect(response).to redirect_to(root_path)
      end
    end

    # Adminは更新可能
    context "Adminが更新" do
      before { sign_in(admin) }

      it "支出記録を更新して一覧ページにリダイレクトする" do
        patch expense_record_path(expense_record), params: valid_params
        expect(response).to redirect_to(expense_records_path)
        expect(expense_record.reload.amount).to eq(9000)
      end
    end
  end

  describe "DELETE /expense_records/:id" do
    let(:expense_record) { create(:expense_record, created_by: admin) }

    # StaffはAdmin専用ページにアクセス不可
    context "Staffが削除しようとする" do
      before { sign_in(staff) }

      it "ルートにリダイレクトする" do
        delete expense_record_path(expense_record)
        expect(response).to redirect_to(root_path)
      end
    end

    # Adminは削除可能
    context "Adminが削除" do
      before { sign_in(admin) }

      it "支出記録を削除して一覧ページにリダイレクトする" do
        delete expense_record_path(expense_record)
        expect(response).to redirect_to(expense_records_path)
        expect { expense_record.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
