# ダイレクトアップロードの入口にログイン必須を足す。
#
# Active Storage のコントローラーはエンジン側の ActiveStorage::BaseController を
# 継承するため、ApplicationController の before_action :require_login が効かない。
# 素のままだと誰でも POST /rails/active_storage/direct_uploads を叩けて、
# Supabase のバケットへ直接アップロードできる署名付きURLを受け取れる。
#
# お知らせ本文の画像でダイレクトアップロードを使い始めたのはこの変更からで、
# それまでは動物の写真がフォーム経由（サーバーがバイト列を受け取る）だけだった。
# 入口が増えたぶん、認証もそこへ付け直す必要がある。
#
# Active Storage のコントローラーには on_load フックが無いので to_prepare で開く。
# 開発環境のコード再読み込みのたびにクラスが作り直されるため、
# initializer で一度だけ書くと再読み込み後に消える。
Rails.application.config.to_prepare do
  ActiveStorage::DirectUploadsController.class_eval do
    before_action :require_logged_in_user

    private

      def require_logged_in_user
        return if User.active.exists?(id: session[:user_id])

        redirect_to Rails.application.routes.url_helpers.login_path,
                    alert: "로그인이 필요합니다."
      end
  end
end
