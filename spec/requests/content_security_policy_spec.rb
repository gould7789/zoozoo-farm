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

  # 裸の https: は任意のhttpsオリジンを許可してしまうので付けない。
  # ダイレクトアップロード先として connect-src に1つだけ具体的なオリジンが入るが、
  # それはホストまで固定されているので別物である
  it "任意のhttpsオリジンを許可しない" do
    expect(csp).not_to match(%r{(?:\A|[;\s])https:(?:[;\s]|\z)})
  end

  # ダイレクトアップロードは署名付きURLへ直接PUTする。
  # connect-src が無いと default-src 'self' が効いて本番でのみ落ちる
  it "connect-srcが自分自身を許可する" do
    expect(csp).to match(/connect-src 'self'/)
  end

  # ストレージのオリジンは本文エディタのある画面にだけ足す。
  # 全体に置くと、未ログインで見えるログイン画面にもホスト名が載る
  describe "ストレージオリジンの適用範囲" do
    def connect_src = response.headers["Content-Security-Policy"].to_s[/connect-src [^;]+/]

    it "ログイン画面には載せない" do
      expect(connect_src).to eq("connect-src 'self'")
    end

    it "お知らせの作成画面には載せる" do
      user = create(:user)
      sign_in(user)
      get new_notice_path

      expect(connect_src).to start_with("connect-src 'self'")
      # ENV が無い環境（CI）では 'self' だけになるので、
      # 「設定があれば足される」ことだけを見る
      if ENV["SUPABASE_S3_ENDPOINT"].present?
        expect(connect_src).to include(ENV["SUPABASE_S3_ENDPOINT"])
      end
    end

    it "お知らせ以外の画面には載せない" do
      user = create(:user)
      sign_in(user)
      get zones_path

      expect(connect_src).to eq("connect-src 'self'")
    end
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
