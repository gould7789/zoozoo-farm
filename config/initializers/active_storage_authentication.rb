# Active Storage の入口すべてにログイン必須を足す。
#
# Active Storage のコントローラーはエンジン側の ActiveStorage::BaseController を
# 継承するため、ApplicationController の before_action :require_login が効かない。
# Rails 自身がソースに警告を書いている —
#   "All Active Storage controllers are publicly accessible by default.
#    Anyone who knows the URL can access the file, even if the rest of your
#    application requires authentication."
# ガイドの Authenticated Controllers がその対処で、ここで実装している。
#
# 素のままだと誰でも POST /rails/active_storage/direct_uploads を叩けて、
# Supabase のバケットへ直接アップロードできる署名付きURLを受け取れた（実測で200）。
# 閲覧側も署名付きURLさえ知っていれば未ログインで開けた。
#
# 個別のコントローラーではなく BaseController に付けるのは、
# 6つの入口を一度に覆えるうえ、Rails が将来コントローラーを増やしても
# 自動で含まれるからである。今回の不具合は「入口が増えたのに気付かなかった」
# ことが原因なので、同じ失敗を構造で防ぐ位置に置く。
#
#   BaseController
#   ├── DirectUploadsController          アップロード申請
#   ├── DiskController                   開発・テストの Disk サービス
#   ├── Blobs::ProxyController           原本（proxy）
#   ├── Blobs::RedirectController        原本（redirect）
#   └── Representations::BaseController
#       ├── Representations::ProxyController
#       └── Representations::RedirectController
#
# 閲覧側は DisableSession が入っていてセッションの書き戻しを止めるが、
# 読み取りは通るので current_user 相当の判定はできる（実測でログイン時200）。
# 代わりに CDN でのキャッシュ対象から外れるが、この規模では CDN を使わない。
#
# Active Storage のコントローラーには on_load フックが無いので to_prepare で開く。
# 開発環境のコード再読み込みのたびにクラスが作り直されるため、
# initializer で一度だけ書くと再読み込み後に消える。
Rails.application.config.to_prepare do
  ActiveStorage::BaseController.class_eval do
    before_action :require_logged_in_user

    private

      def require_logged_in_user
        return if User.active.exists?(id: session[:user_id])

        redirect_to Rails.application.routes.url_helpers.login_path,
                    alert: "로그인이 필요합니다."
      end
  end
end
