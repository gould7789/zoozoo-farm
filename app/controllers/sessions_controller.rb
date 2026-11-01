# 인증(로그인·로그아웃) 담당
# 판단 근거는 .claude/rules/notes/auth.md
class SessionsController < ApplicationController
  skip_before_action :require_login, only: [ :new, :create ]

  # 무차별 대입 대비. IP 가 아니라 이메일 기준인 이유는 현장이 같은 Wi-Fi(NAT) 아래라서다
  rate_limit to: 10, within: 3.minutes, only: :create,
             by: -> { params[:email].to_s.downcase.strip },
             with: -> {
               redirect_to login_path,
                           alert: "로그인 시도가 너무 많습니다. 잠시 후 다시 시도해주세요."
             }

  def new
    redirect_to root_path if logged_in?
  end

  def create
    user = User.active.find_by(email: params[:email])

    if user&.authenticate(params[:password])
      # 세션 고정 공격을 막기 위해 로그인 성공 시 세션 ID 를 다시 만든다
      reset_session
      session[:user_id] = user.id
      redirect_to root_path, notice: "로그인했습니다."
    else
      flash.now[:alert] = "이메일 또는 비밀번호가 올바르지 않습니다."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    # reset_session 을 redirect 보다 먼저 불러야 한다 — 나중에 부르면 flash 가 세션째로 지워진다
    reset_session
    redirect_to login_path, notice: "로그아웃했습니다."
  end
end
