# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.font_src    :self, :data
    # :blob は Trix が添付を選んだ直後に出すプレビューのため。
    # URL.createObjectURL は同一オリジンのスクリプトしか作れないので、
    # これを許しても外部から画像を読み込めるようにはならない
    policy.img_src     :self, :data, :blob
    policy.object_src  :none
    # 既定は自分自身のみ。ストレージのオリジンは NoticesController だけに足す。
    # 全ページに書くと、未ログインで見えるログイン画面にも
    # ストレージのホスト名が載ってしまう
    policy.connect_src :self
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
