# Admin専用ユーザー管理コントローラー — Staffアカウントの作成・編集・退職処理を担当
class Admin::UsersController < ApplicationController
  before_action :require_admin
  before_action :set_user, only: [ :edit, :update ]

  def index
    # アクティブ・非アクティブ両方表示（退職者も確認できるように）
    # 役割ごとに分けて表示するため別々に取得
    @admins = User.admin.order(:name)
    @staffs = User.staff.order(:name)
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      redirect_to admin_users_path, notice: "계정을 생성했습니다."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @user.update(user_update_params)
      redirect_to admin_users_path, notice: "계정 정보를 수정했습니다."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

    def set_user
      @user = User.find(params[:id])
    end

    # 新規作成用パラメータ — パスワード必須
    def user_params
      permitted = params.require(:user).permit(:name, :email, :password, :role, :position, :is_team_leader, :hired_on, :contract_ends_on)
      # positionが空文字の場合はnilに変換（enumに空文字を渡すとArgumentErrorになるため）
      permitted[:position] = nil if permitted[:position].blank?
      permitted
    end

    # 更新用パラメータ — パスワードは任意（空の場合は変更しない）、退職処理(active)も含む
    def user_update_params
      permitted = params.require(:user).permit(:name, :email, :password, :role, :active,
                                               :position, :is_team_leader, :hired_on, :contract_ends_on)
      # パスワードが空欄の場合は更新しない
      permitted.delete(:password) if permitted[:password].blank?
      # positionが空文字の場合はnilに変換
      permitted[:position] = nil if permitted[:position].blank?
      permitted
    end
end
