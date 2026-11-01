# 마이페이지 — 로그인한 사용자의 정보를 보여준다 (읽기 전용)
class AccountsController < ApplicationController
  before_action :require_login

  def show
    @user = current_user
  end
end
