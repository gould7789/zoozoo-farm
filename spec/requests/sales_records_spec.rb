# SalesRecordsController — Admin 전용 접근 제어와 연월 필터
require "rails_helper"

RSpec.describe "SalesRecords", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:staff) { create(:user) }

  describe "GET /sales_records" do
    context "비로그인" do
      before { get sales_path }
      it_behaves_like "로그인이 필요하다"
    end

    context "Staff 가 접근" do
      before { sign_in(staff); get sales_path }
      it_behaves_like "접근이 거부된다"
    end

    context "Admin 이 접근" do
      before { sign_in(admin); get sales_path }
      it { expect(response).to have_http_status(:ok) }
    end

    # 연월 필터 — params 를 그대로 믿지 않고 존재하는 연월인지 확인한다.
    # month=99 가 Date.new 에 넘어가면 ArgumentError 라 폴백이 필수다
    context "없는 연월을 지정한 경우" do
      before { sign_in(admin) }

      it "500 이 되지 않고 최신 월로 떨어진다" do
        create(:sales_record, created_by: admin, sold_on: Date.new(2026, 4, 15), source: :vending_1)

        get sales_path(year: 1999, month: 99)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("2026년 04월")
      end
    end

    context "연월을 지정한 경우" do
      before { sign_in(admin) }

      it "선택한 월의 레코드만 보여준다" do
        create(:sales_record, created_by: admin, sold_on: Date.new(2026, 4, 15), source: :vending_1, amount: 12_345)
        create(:sales_record, created_by: admin, sold_on: Date.new(2026, 5, 15), source: :vending_2, amount: 98_765)

        get sales_path(year: 2026, month: 4)

        expect(response.body).to include("12,345")
        expect(response.body).not_to include("98,765")
      end
    end
  end

  describe "GET /sales_records/new" do
    context "비로그인" do
      before { get new_sale_path }
      it_behaves_like "로그인이 필요하다"
    end

    context "Staff 가 접근" do
      before { sign_in(staff); get new_sale_path }
      it_behaves_like "접근이 거부된다"
    end

    context "Admin 이 접근" do
      before { sign_in(admin); get new_sale_path }
      it { expect(response).to have_http_status(:ok) }
    end
  end

  describe "POST /sales_records" do
    let(:valid_params) do
      { sales_record: { sold_on: Date.today, source: "vending_1", amount: 5000 } }
    end

    context "비로그인" do
      before { post sales_path, params: valid_params }
      it_behaves_like "로그인이 필요하다"
    end

    context "Staff 가 작성을 시도" do
      before { sign_in(staff); post sales_path, params: valid_params }
      it_behaves_like "접근이 거부된다"
    end

    context "Admin 이 작성" do
      before { sign_in(admin) }

      it "created_by 가 자기 ID 로 저장되고 목록으로 보낸다" do
        post sales_path, params: valid_params
        expect(response).to redirect_to(sales_path)
        expect(SalesRecord.last.created_by).to eq(admin)
      end
    end
  end

  describe "GET /sales_records/:id/edit" do
    let(:sales_record) { create(:sales_record, created_by: admin) }

    context "Staff 가 접근" do
      before { sign_in(staff); get edit_sale_path(sales_record) }
      it_behaves_like "접근이 거부된다"
    end

    context "Admin 이 접근" do
      before { sign_in(admin); get edit_sale_path(sales_record) }
      it { expect(response).to have_http_status(:ok) }
    end
  end

  describe "PATCH /sales_records/:id" do
    let(:sales_record) { create(:sales_record, created_by: admin) }
    let(:valid_params) { { sales_record: { amount: 9000 } } }

    context "Staff 가 수정을 시도" do
      before { sign_in(staff); patch sale_path(sales_record), params: valid_params }
      it_behaves_like "접근이 거부된다"
    end

    context "Admin 이 수정" do
      before { sign_in(admin) }

      it "매출 기록을 수정하고 목록으로 보낸다" do
        patch sale_path(sales_record), params: valid_params
        expect(response).to redirect_to(sales_path)
        expect(sales_record.reload.amount).to eq(9000)
      end
    end
  end

  describe "DELETE /sales_records/:id" do
    let(:sales_record) { create(:sales_record, created_by: admin) }

    context "Staff 가 삭제를 시도" do
      before { sign_in(staff); delete sale_path(sales_record) }
      it_behaves_like "접근이 거부된다"
    end

    context "Admin 이 삭제" do
      before { sign_in(admin) }

      it "매출 기록을 삭제하고 목록으로 보낸다" do
        delete sale_path(sales_record)
        expect(response).to redirect_to(sales_path)
        expect { sales_record.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
