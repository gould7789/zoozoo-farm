require "rails_helper"

RSpec.describe "Content Security Policy", type: :request do
  # 비로그인으로 닿는 화면에서 본다. 세션 쿠키가 없는 첫 요청은 nonce 가 비기 쉽고,
  # 빈 nonce 는 명세상 어느 스크립트와도 일치하지 않으므로 반드시 확인한다
  subject(:csp) { response.headers["Content-Security-Policy"] }

  before { get login_path }

  it "CSP 헤더를 반환한다" do
    expect(csp).to be_present
    expect(csp).to include("default-src 'self'")
    expect(csp).to include("object-src 'none'")
  end

  # 맨 https: 는 임의의 https 오리진을 허용하므로 쓰지 않는다.
  # connect-src 에 구체적인 오리진이 하나 들어가지만 그건 호스트까지 고정돼 있어 다른 것이다
  it "임의의 https 오리진을 허용하지 않는다" do
    expect(csp).not_to match(%r{(?:\A|[;\s])https:(?:[;\s]|\z)})
  end

  # connect-src 가 없으면 default-src 'self' 가 들어 운영에서만 떨어진다
  it "connect-src 가 자기 자신을 허용한다" do
    expect(csp).to match(/connect-src 'self'/)
  end

  # 스토리지 오리진은 본문 에디터가 있는 화면에만 붙인다 (notes/notice.md)
  describe "스토리지 오리진의 적용 범위" do
    def connect_src = response.headers["Content-Security-Policy"].to_s[/connect-src [^;]+/]

    it "로그인 화면에는 싣지 않는다" do
      expect(connect_src).to eq("connect-src 'self'")
    end

    it "공지 작성 화면에는 싣는다" do
      user = create(:user)
      sign_in(user)
      get new_notice_path

      expect(connect_src).to start_with("connect-src 'self'")
      # ENV 가 없는 환경(CI)에서는 'self' 뿐이라 「설정이 있으면 붙는다」만 본다
      if ENV["SUPABASE_S3_ENDPOINT"].present?
        expect(connect_src).to include(URI.parse(ENV["SUPABASE_S3_ENDPOINT"]).host)
      end
    end

    # 경로를 넣으면 완전 일치가 요구돼 운영에서만 업로드가 떨어진다 (notes/notice.md)
    it "경로를 넣지 않는다 (오리진만)" do
      skip "ENV 미설정" if ENV["SUPABASE_S3_ENDPOINT"].blank?

      user = create(:user)
      sign_in(user)
      get new_notice_path

      origin = connect_src[%r{https://\S+}]
      expect(URI.parse(origin).path).to eq("")
    end

    it "공지 외의 화면에는 싣지 않는다" do
      user = create(:user)
      sign_in(user)
      get zones_path

      expect(connect_src).to eq("connect-src 'self'")
    end
  end

  it "script-src 에 비어 있지 않은 nonce 가 들어 있다" do
    expect(csp).to match(/script-src 'self' 'nonce-[^']+'/)
  end

  it "style-src 에 비어 있지 않은 nonce 가 들어 있다" do
    expect(csp).to match(/style-src 'self' 'nonce-[^']+'/)
  end

  it "unsafe-inline 을 넣지 않는다" do
    expect(csp).not_to include("unsafe-inline")
  end

  # 헤더의 nonce 와 실제 script 태그의 nonce 가 다르면 스크립트가 돌지 않는다
  it "importmap 의 script 태그에 헤더와 같은 nonce 가 붙는다" do
    nonce = csp[/script-src 'self' 'nonce-([^']+)'/, 1]

    expect(nonce).to be_present
    expect(response.body).to include(%(nonce="#{nonce}"))
  end
end
