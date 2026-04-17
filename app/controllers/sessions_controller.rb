# 認証（ログイン・ログアウト）を担当するコントローラー
class SessionsController < ApplicationController
  # ログインページは認証不要
  skip_before_action :require_login, only: [ :new, :create ]

  def new
    # ログイン済みならルートへリダイレクト
    redirect_to root_path if logged_in?
  end

  def create
    user = User.active.find_by(email: params[:email])

    if user&.authenticate(params[:password])
      # セッション固定攻撃を防ぐためログイン成功時にセッションIDを再生成する
      reset_session
      session[:user_id] = user.id
      redirect_to root_path, notice: "로그인했습니다."
    else
      flash.now[:alert] = "이메일 또는 비밀번호가 올바르지 않습니다."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    session.delete(:user_id)
    redirect_to login_path, notice: "로그아웃했습니다."
  end
end
