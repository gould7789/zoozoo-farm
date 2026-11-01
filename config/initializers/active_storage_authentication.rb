# Active Storage 의 입구 전부에 로그인 필수를 더한다.
#
# Active Storage 의 컨트롤러는 엔진 쪽 ActiveStorage::BaseController 를 상속해서
# ApplicationController 의 before_action :require_login 이 듣지 않는다.
# Rails 자신이 소스에 경고를 써 두고 있다 —
#   "All Active Storage controllers are publicly accessible by default."
# 가이드의 Authenticated Controllers 가 그 대처이고, 여기서 구현한다.
#
# 손대지 않으면 누구나 POST /rails/active_storage/direct_uploads 를 때려
# Supabase 버킷에 직접 올릴 수 있는 서명된 URL 을 받았다(실측 200).
# 열람 쪽도 서명된 URL 만 알면 비로그인으로 열렸다.
#
# 개별 컨트롤러가 아니라 BaseController 에 붙이는 이유는, 입구 6개를 한 번에
# 덮으면서 Rails 가 나중에 컨트롤러를 늘려도 자동으로 포함되기 때문이다.
# 이번 결함의 원인이 「입구가 늘었는데 알아채지 못했다」이므로 구조로 막는 자리에 둔다.
#
#   BaseController
#   ├── DirectUploadsController          업로드 신청
#   ├── DiskController                   개발과 테스트의 Disk 서비스
#   ├── Blobs::ProxyController           원본 (proxy)
#   ├── Blobs::RedirectController        원본 (redirect)
#   └── Representations::BaseController
#       ├── Representations::ProxyController
#       └── Representations::RedirectController
#
# 열람 쪽은 DisableSession 이 들어 세션 쓰기를 멈추지만 읽기는 통하므로
# current_user 에 해당하는 판정은 된다(실측으로 로그인 시 200).
# 대신 CDN 캐시 대상에서 빠지는데, 이 규모에서는 CDN 을 쓰지 않는다.
#
# Active Storage 의 컨트롤러에는 on_load 훅이 없어 to_prepare 로 연다.
# 개발 환경은 코드를 다시 읽을 때마다 클래스가 새로 만들어지므로,
# initializer 에서 한 번만 쓰면 재적재 뒤에 사라진다.
#
# 전체 경위는 docs/active-storage.md
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
