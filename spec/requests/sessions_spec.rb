require "rails_helper"

RSpec.describe "Sessions", type: :request do
  describe "GET /login" do
    it "로그인 화면을 보여준다" do
      get login_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /login" do
    let(:user) { create(:user, password: "password123") }

    context "올바른 인증 정보" do
      it "루트로 보낸다" do
        post login_path, params: { email: user.email, password: "password123" }
        expect(response).to redirect_to(root_path)
      end

      it "세션에 user_id 를 저장한다" do
        post login_path, params: { email: user.email, password: "password123" }
        expect(session[:user_id]).to eq(user.id)
      end
    end

    context "틀린 비밀번호" do
      it "로그인 화면으로 돌아간다" do
        post login_path, params: { email: user.email, password: "wrongpassword" }
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "세션에 user_id 를 저장하지 않는다" do
        post login_path, params: { email: user.email, password: "wrongpassword" }
        expect(session[:user_id]).to be_nil
      end
    end

    context "퇴사 처리된 사용자" do
      let(:inactive_user) { create(:user, :inactive, password: "password123") }

      it "로그인되지 않는다" do
        post login_path, params: { email: inactive_user.email, password: "password123" }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "DELETE /logout" do
    before do
      user = create(:user, password: "password123")
      post login_path, params: { email: user.email, password: "password123" }
    end

    it "로그아웃 뒤에는 로그인 화면으로 보낸다" do
      delete logout_path
      expect(response).to redirect_to(login_path)
    end

    it "세션의 user_id 를 지운다" do
      delete logout_path
      expect(session[:user_id]).to be_nil
    end

    # user_id 만 지우면 세션 ID 가 재사용된다 (notes/auth.md)
    it "세션을 완전히 버린다" do
      # session.id 는 Rack::Session::SessionId 객체를 돌려준다. 이 클래스는 == 를
      # 정의하지 않아 객체 동일성으로 비교되므로, 값을 비교하려면 반드시 문자열화한다
      # (그냥 비교하면 항상 통과하는 무의미한 테스트가 된다)
      session_id_before = session.id.to_s

      delete logout_path

      expect(session_id_before).to be_present
      expect(session.id.to_s).not_to eq(session_id_before)
    end
  end

  # 무차별 대입 대비 — 같은 이메일로의 시도를 10회/3분으로 제한한다
  describe "로그인 시도 제한" do
    let(:user) { create(:user, password: "password123") }

    it "같은 이메일로의 시도가 상한을 넘으면 막힌다" do
      10.times do
        post login_path, params: { email: user.email, password: "wrongpassword" }
      end

      # 11회째는 올바른 비밀번호여도 막힌다
      post login_path, params: { email: user.email, password: "password123" }

      expect(response).to redirect_to(login_path)
      expect(flash[:alert]).to eq("로그인 시도가 너무 많습니다. 잠시 후 다시 시도해주세요.")
      expect(session[:user_id]).to be_nil
    end

    # by: 가 IP 가 아니라 이메일 기준인지 확인한다 —
    # 같은 Wi-Fi(NAT) 아래의 다른 직원이 휘말리지 않아야 한다
    it "다른 이메일은 영향을 받지 않는다" do
      11.times do
        post login_path, params: { email: user.email, password: "wrongpassword" }
      end

      other_user = create(:user, password: "password123")
      post login_path, params: { email: other_user.email, password: "password123" }

      expect(response).to redirect_to(root_path)
      expect(session[:user_id]).to eq(other_user.id)
    end

    # rate_limit 은 `count = store.increment(...)` / `if count && count > to` 로
    # 판정하므로, 스토어가 세지 못하면 예외도 경고도 없이 전부 통과시킨다.
    # 위의 두 예제는 memory_store 전제로 통과해 스토어가 깨진 것을 못 잡는다.
    # 여기가 먼저 떨어지면 원인이 스토어임을 바로 알 수 있다.
    describe "백킹 스토어" do
      it "rate limit 용 테이블이 스키마에 있다" do
        # 운영은 solid_cache_store — 이 테이블이 없으면 increment 가 UndefinedTable 로 떨어진다
        expect(ActiveRecord::Base.connection).to be_table_exists("solid_cache_entries")
      end

      it "increment 가 더한 뒤의 값을 반환한다" do
        # null_store 의 increment 는 빈 메서드로 nil 을 돌려 판정이 통째로 건너뛰어진다
        store = ActionController::Base.cache_store
        expect(store.increment("spec:rate-limit-probe", 1, expires_in: 1.minute)).to eq(1)
      end
    end
  end

  describe "비로그인 접근 제한" do
    it "보호된 화면은 로그인 화면으로 보낸다" do
      get root_path
      expect(response).to redirect_to(login_path)
    end
  end

  # 기본값은 expire_after 가 없어 브라우저를 닫을 때까지 쿠키가 산다.
  # 현장 스마트폰은 브라우저를 거의 닫지 않아 사실상 무기한이었다.
  describe "세션 유효 기간" do
    it "9시간에 끊기는 쿠키를 낸다" do
      expect(Rails.application.config.session_options[:expire_after]).to eq(9.hours)
    end

    it "로그인 시 Set-Cookie 에 기한이 붙는다" do
      user = create(:user)
      post login_path, params: { email: user.email, password: "password123" }

      cookie = response.headers["Set-Cookie"].to_s
      expect(cookie).to include("_zoo_keeper_session")
      expect(cookie).to match(/expires=/i)
    end
  end
end
