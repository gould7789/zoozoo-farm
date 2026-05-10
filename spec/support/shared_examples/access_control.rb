# アクセス制御の共通テストパターン
# 使い方: beforeブロックでHTTPリクエストを発行してから it_behaves_like で呼び出す
#
# 例:
#   context "未ログイン" do
#     before { get some_path }
#     it_behaves_like "ログインが必要"
#   end

RSpec.shared_examples "ログインが必要" do
  it "ログインページにリダイレクトする" do
    expect(response).to redirect_to(login_path)
  end
end

RSpec.shared_examples "アクセス拒否" do
  it "ルートにリダイレクトする" do
    expect(response).to redirect_to(root_path)
  end
end
