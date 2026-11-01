# Admin 전용 대시보드 — 모바일 「관리」 탭의 입구
class Admin::DashboardController < ApplicationController
  before_action :require_login
  before_action :require_admin

  def index; end
end
