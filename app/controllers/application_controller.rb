# 全コントローラーの基底クラス — 認証ヘルパーを定義
class ApplicationController < ActionController::Base
  # 最新ブラウザのみ許可
  allow_browser versions: :modern

  # importmapの変更時にHTMLレスポンスのetagを無効化
  stale_when_importmap_changes

  before_action :require_login

  helper_method :current_user, :logged_in?

  private

    def current_user
      @current_user ||= User.active.find_by(id: session[:user_id])
    end

    def logged_in?
      current_user.present?
    end

    def require_login
      redirect_to login_path, alert: "로그인이 필요합니다." unless logged_in?
    end

    def require_admin
      redirect_to root_path, alert: "권한이 없습니다." unless current_user&.admin?
    end
end
