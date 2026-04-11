# Admin専用ダッシュボード — モバイルの「管理」タブの入口
class Admin::DashboardController < ApplicationController
  before_action :require_login
  before_action :require_admin

  def index; end
end
