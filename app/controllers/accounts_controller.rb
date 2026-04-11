# マイページ — ログインユーザーの情報を表示する（読み取り専用）
class AccountsController < ApplicationController
  before_action :require_login

  def show
    @user = current_user
  end
end
