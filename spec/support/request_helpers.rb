# 요청 스펙용 헬퍼 — rails_helper 가 type: :request 에 include 한다
module RequestHelpers
  # 로그인 상태를 만든다 — 비밀번호는 팩토리의 고정값 "password123"
  def sign_in(user)
    post login_path, params: { email: user.email, password: "password123" }
  end
end
