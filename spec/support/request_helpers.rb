# リクエストスペック用のヘルパーメソッド
# rails_helperでtype: :requestのスペックにインクルードされる
module RequestHelpers
  # ログイン状態を作るヘルパー — パスワードはfactoryの固定値"password123"を使用
  def sign_in(user)
    post login_path, params: { email: user.email, password: "password123" }
  end
end
