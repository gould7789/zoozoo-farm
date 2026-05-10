# お知らせのCRUDを担当するコントローラー
# 全アクションにログイン必須、編集・削除は本人記録のみ（Adminは他者記録も操作可能）
class NoticesController < ApplicationController
  include OwnerRestriction

  before_action :set_notice,                    only: [ :edit, :update, :destroy ]
  before_action -> { require_owner(@notice) },  only: [ :edit, :update, :destroy ]

  def index
    @notices = Notice.recent
  end

  def new
    @notice = Notice.new
  end

  def create
    @notice = Notice.new(notice_params)
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

    def notice_params
      params.require(:notice).permit(:category, :body)
    end
end
