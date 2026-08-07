require "rails_helper"

RSpec.describe "Content Security Policy", type: :request do
  # 未ログインで到達できるページで検証する
  # セッションクッキーが無い最初のリクエストはnonceが空になりやすく、
  # 空のnonceはCSP仕様上どのスクリプトともマッチしないため必ず確認する
  subject(:csp) { response.headers["Content-Security-Policy"] }

  before { get login_path }

  it "CSPヘッダーを返す" do
    expect(csp).to be_present
    expect(csp).to include("default-src 'self'")
    expect(csp).to include("object-src 'none'")
  end

  # 外部参照が0件のため:httpsは付けない — 付けると任意のhttpsオリジンを許可してしまう
  it "任意のhttpsオリジンを許可しない" do
    expect(csp).not_to include("https:")
  end

  # importmapが出力するインラインスクリプト用
  it "script-srcに空でないnonceが含まれる" do
    expect(csp).to match(/script-src 'self' 'nonce-[^']+'/)
  end

  # Turboが実行時に注入する進捗バーの<style>用
  it "style-srcに空でないnonceが含まれる" do
    expect(csp).to match(/style-src 'self' 'nonce-[^']+'/)
  end

  it "unsafe-inlineを含まない" do
    expect(csp).not_to include("unsafe-inline")
  end

  # ヘッダーのnonceと実際のscriptタグのnonceが一致しなければスクリプトは動かない
  it "importmapのscriptタグにヘッダーと同じnonceが付く" do
    nonce = csp[/script-src 'self' 'nonce-([^']+)'/, 1]

    expect(nonce).to be_present
    expect(response.body).to include(%(nonce="#{nonce}"))
  end
end
