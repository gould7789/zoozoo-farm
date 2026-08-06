# ExpenseRecordsControllerのリクエストテスト — Admin専用アクセス制御を中心に検証する
require "rails_helper"

RSpec.describe "ExpenseRecords", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:staff) { create(:user) }

  describe "GET /expense_records" do
    context "未ログイン" do
      before { get expenses_path }
      it_behaves_like "ログインが必要"
    end

    context "Staffがアクセス" do
      before { sign_in(staff); get expenses_path }
      it_behaves_like "アクセス拒否"
    end

    context "Adminがアクセス" do
      before { sign_in(admin); get expenses_path }
      it { expect(response).to have_http_status(:ok) }
    end

    # 年月フィルタ — パラメータをそのまま信用せず、存在する年月かを検証している
    # month=99がDate.newに渡るとArgumentErrorになるため、フォールバックが必須
    context "存在しない年・月を指定した場合" do
      before { sign_in(admin) }

      it "500にならず最新月にフォールバックする" do
        create(:expense_record, created_by: admin, spent_on: Date.new(2026, 4, 15))

        get expenses_path(year: 1999, month: 99)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("2026년 04월")
      end
    end

    context "年月を指定した場合" do
      before { sign_in(admin) }

      it "選択した月のレコードだけを表示する" do
        create(:expense_record, created_by: admin, spent_on: Date.new(2026, 4, 15), amount: 12_345)
        create(:expense_record, created_by: admin, spent_on: Date.new(2026, 5, 15), amount: 98_765)

        get expenses_path(year: 2026, month: 4)

        expect(response.body).to include("12,345")
        expect(response.body).not_to include("98,765")
      end
    end
  end

  describe "GET /expense_records/new" do
    context "未ログイン" do
      before { get new_expense_path }
      it_behaves_like "ログインが必要"
    end

    context "Staffがアクセス" do
      before { sign_in(staff); get new_expense_path }
      it_behaves_like "アクセス拒否"
    end

    context "Adminがアクセス" do
      before { sign_in(admin); get new_expense_path }
      it { expect(response).to have_http_status(:ok) }
    end
  end

  describe "POST /expense_records" do
    let(:valid_params) do
      { expense_record: { spent_on: Date.today, category: "food", amount: 5000, description: "먹이 구매" } }
    end

    context "未ログイン" do
      before { post expenses_path, params: valid_params }
      it_behaves_like "ログインが必要"
    end

    context "Staffが作成しようとする" do
      before { sign_in(staff); post expenses_path, params: valid_params }
      it_behaves_like "アクセス拒否"
    end

    context "Adminが作成" do
      before { sign_in(admin) }

      it "created_byが自分のIDで保存されて一覧ページにリダイレクトする" do
        post expenses_path, params: valid_params
        expect(response).to redirect_to(expenses_path)
        expect(ExpenseRecord.last.created_by).to eq(admin)
      end
    end
  end

  describe "GET /expense_records/:id/edit" do
    let(:expense_record) { create(:expense_record, created_by: admin) }

    context "Staffがアクセス" do
      before { sign_in(staff); get edit_expense_path(expense_record) }
      it_behaves_like "アクセス拒否"
    end

    context "Adminがアクセス" do
      before { sign_in(admin); get edit_expense_path(expense_record) }
      it { expect(response).to have_http_status(:ok) }
    end
  end

  describe "PATCH /expense_records/:id" do
    let(:expense_record) { create(:expense_record, created_by: admin) }
    let(:valid_params) { { expense_record: { amount: 9000 } } }

    context "Staffが更新しようとする" do
      before { sign_in(staff); patch expense_path(expense_record), params: valid_params }
      it_behaves_like "アクセス拒否"
    end

    context "Adminが更新" do
      before { sign_in(admin) }

      it "支出記録を更新して一覧ページにリダイレクトする" do
        patch expense_path(expense_record), params: valid_params
        expect(response).to redirect_to(expenses_path)
        expect(expense_record.reload.amount).to eq(9000)
      end
    end
  end

  describe "DELETE /expense_records/:id" do
    let(:expense_record) { create(:expense_record, created_by: admin) }

    context "Staffが削除しようとする" do
      before { sign_in(staff); delete expense_path(expense_record) }
      it_behaves_like "アクセス拒否"
    end

    context "Adminが削除" do
      before { sign_in(admin) }

      it "支出記録を削除して一覧ページにリダイレクトする" do
        delete expense_path(expense_record)
        expect(response).to redirect_to(expenses_path)
        expect { expense_record.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
