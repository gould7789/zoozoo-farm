# お知らせのCRUDを担当するコントローラー
# 全アクションにログイン必須、編集・削除は本人記録のみ（Adminは他者記録も操作可能）
class NoticesController < ApplicationController
  before_action :set_notice, only: [ :edit, :update, :destroy ]
  before_action :require_owner, only: [ :edit, :update, :destroy ]

  def index
    # 最新投稿順に表示
    @notices = Notice.recent
  end

  def new
    @notice = Notice.new
  end

  def create
    @notice = Notice.new(notice_params)
    # created_byは必ずログイン中のユーザーを設定
    @notice.created_by = current_user
    if @notice.save
      redirect_to notices_path, notice: "공지를 등록했습니다."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @notice.update(notice_params)
      redirect_to notices_path, notice: "공지를 수정했습니다."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @notice.destroy
    redirect_to notices_path, notice: "공지를 삭제했습니다."
  end

  private

    def set_notice
      @notice = Notice.find(params[:id])
    end

    # 本人記録かAdminのみ編集・削除可能
    def require_owner
      unless current_user.admin? || @notice.created_by_id == current_user.id
        redirect_to root_path, alert: "권한이 없습니다."
      end
    end

    # ストロングパラメータ — created_byはコントローラーで強制設定するので除外
    def notice_params
      params.require(:notice).permit(:category, :body)
    end
end
