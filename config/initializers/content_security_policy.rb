# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.font_src    :self, :data
    # :blob 은 Trix 가 첨부를 고른 직후 내는 미리보기용.
    # URL.createObjectURL 은 같은 오리진의 스크립트만 만들 수 있어
    # 이걸 허용해도 외부에서 이미지를 읽어올 수 있게 되지는 않는다
    policy.img_src     :self, :data, :blob
    policy.object_src  :none
    # 기본은 자기 자신만. 스토리지 오리진은 NoticesController 에만 더한다
    # (.claude/rules/notes/notice.md)
    policy.connect_src :self
    policy.script_src  :self
    policy.style_src   :self
  end

  # importmap 이 내는 인라인 스크립트와 Turbo 가 실행 중 끼워 넣는
  # 진행 바의 <style> 을 허용하기 위한 nonce — style-src 를 빼면 진행 바가 막힌다
  #
  # Rails 템플릿은 request.session.id.to_s 를 쓰지만 그건 쓰지 않는다.
  # 세션 쿠키가 아직 없는 첫 요청(= 로그인 화면)에서는 id 가 nil 이 되어
  # 'nonce-' 라는 빈 nonce 가 나온다. 빈 nonce 는 명세상 어느 스크립트와도
  # 일치하지 않아 importmap 이 통째로 막힌다.
  # 요청마다 만들면 비지 않고, 같은 세션 안에서 값이 재사용되지도 않는다
  config.content_security_policy_nonce_generator = ->(_request) { SecureRandom.base64(16) }
  config.content_security_policy_nonce_directives = %w[ script-src style-src ]
end
