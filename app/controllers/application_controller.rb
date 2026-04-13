# 全コントローラーの基底クラス — 認証ヘルパーを定義
class ApplicationController < ActionController::Base
  # 最新ブラウザのみ許可
  allow_browser versions: :modern

  # importmapの変更時にHTMLレスポンスのetagを無効化
  stale_when_importmap_changes

  before_action :require_login

  helper_method :current_user, :logged_in?

  # 範囲外の数値がDBに渡された場合（integer overflow等）
  rescue_from ActiveRecord::RangeError do
    redirect_back fallback_location: root_path,
                  alert: "입력값이 허용 범위를 초과했습니다. 숫자를 확인해주세요."
  end

  # 存在しないレコードへのアクセス
  rescue_from ActiveRecord::RecordNotFound do
    redirect_to root_path, alert: "요청한 데이터를 찾을 수 없습니다."
  end

  # Strong Parametersの必須キーが欠落している場合
  rescue_from ActionController::ParameterMissing do
    redirect_back fallback_location: root_path,
                  alert: "필수 항목이 누락됐습니다."
  end

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
