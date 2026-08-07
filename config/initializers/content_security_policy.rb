# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.font_src    :self, :data
    policy.img_src     :self, :data
    policy.object_src  :none
    policy.script_src  :self
    policy.style_src   :self
  end

  # importmapが出力するインラインスクリプトと、Turboが実行時に注入する
  # 進捗バーの<style>を許可するためのnonce
  # style-srcを外すとTurboの進捗バーがブロックされる
  #
  # Railsのテンプレートは request.session.id.to_s を使うが、それは採用しない
  # セッションクッキーがまだ無い最初のリクエスト（＝ログイン画面）ではidがnilになり、
  # 'nonce-' という空のnonceが出力される
  # 空のnonceはCSP仕様上どのスクリプトともマッチしないため、importmapが丸ごとブロックされる
  # リクエストごとに生成すれば空にならず、同一セッション内で値が使い回されることもない
  config.content_security_policy_nonce_generator = ->(_request) { SecureRandom.base64(16) }
  config.content_security_policy_nonce_directives = %w[ script-src style-src ]
end
