# 접근 제어 공통 패턴
# 쓰는 법: before 에서 HTTP 요청을 낸 뒤 it_behaves_like 로 부른다
#
#   context "비로그인" do
#     before { get some_path }
#     it_behaves_like "로그인이 필요하다"
#   end

RSpec.shared_examples "로그인이 필요하다" do
  it "로그인 화면으로 보낸다" do
    expect(response).to redirect_to(login_path)
  end
end

RSpec.shared_examples "접근이 거부된다" do
  it "루트로 보낸다" do
    expect(response).to redirect_to(root_path)
  end
end
