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
      session[:user_id] = user.id
      redirect_to root_path, notice: "ログインしました"
    else
      flash.now[:alert] = "メールアドレスまたはパスワードが間違っています"
      render :new, status: :unprocessable_content
    end
  end

  def destroy
    session.delete(:user_id)
    redirect_to login_path, notice: "ログアウトしました"
  end
end
