# 認証（ログイン・ログアウト）を担当するコントローラー
class SessionsController < ApplicationController
  # ログインページは認証不要
  skip_before_action :require_login, only: [ :new, :create ]

  # ブルートフォース攻撃対策 — 同一メールアドレスへのログイン試行を制限する
  # IPではなくメールアドレスを基準にする理由:
  #   現場は同一Wi-Fi（NAT）配下から複数人が接続するため、IP基準だと
  #   誰か一人の入力ミスで全員が締め出される
  # 大文字小文字・前後の空白で制限をすり抜けられないよう正規化する
  rate_limit to: 10, within: 3.minutes, only: :create,
             by: -> { params[:email].to_s.downcase.strip },
             with: -> {
               redirect_to login_path,
                           alert: "로그인 시도가 너무 많습니다. 잠시 후 다시 시도해주세요."
             }

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
    # セッションIDごと破棄する — ログイン時のreset_sessionと対称にし、値の消し忘れを防ぐ
    # reset_sessionを先に呼ぶこと（後にするとflashがセッションごと消えて通知が出ない）
    reset_session
    redirect_to login_path, notice: "로그아웃했습니다."
  end
end
