# お知らせのCRUDを担当するコントローラー
# 全アクションにログイン必須、編集・削除は本人記録のみ（Adminは他者記録も操作可能）
class NoticesController < ApplicationController
  include OwnerRestriction

  before_action :set_notice,                    only: [ :edit, :update, :destroy ]
  before_action -> { require_owner(@notice) },  only: [ :edit, :update, :destroy ]

  def index
    # 本文は action_text_rich_texts、埋め込み画像は Active Storage の別テーブルにある。
    # with_rich_text_content_and_embeds を外すと一覧の件数ぶんクエリが増える
    @notices = Notice.recent.includes(:created_by).with_rich_text_content_and_embeds
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
      # :body ではなく :content。本文は notices.body ではなく
      # action_text_rich_texts に入るようになった
      params.require(:notice).permit(:category, :title, :content)
    end
end
