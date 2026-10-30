# お知らせのCRUDを担当するコントローラー
# 全アクションにログイン必須、編集・削除は本人記録のみ（Adminは他者記録も操作可能）
class NoticesController < ApplicationController
  include OwnerRestriction

  # 本文エディタのダイレクトアップロードは署名付きURLへ直接PUTする。
  # connect_src を書かないと default_src :self が適用されて弾かれるが、
  # 必要なのはこのコントローラーだけなので全体ではなくここに足す。
  # 全体に置くと未ログインで見えるログイン画面にもホスト名が載る。
  #
  # 開発・テストは Disk サービスで同一オリジンのため、
  # これが無くても落ちない。本番でだけ効く
  content_security_policy do |policy|
    policy.connect_src :self, *[ ENV["SUPABASE_S3_ENDPOINT"] ].compact
  end

  before_action :set_notice,                    only: [ :show, :edit, :update, :destroy ]
  before_action -> { require_owner(@notice) },  only: [ :edit, :update, :destroy ]

  def index
    @category = Notice.categories.key?(params[:category]) ? params[:category] : nil

    # 一覧は抜粋と写真の枚数しか出さないが、どちらも本文を読む必要がある。
    # with_rich_text_content_and_embeds を外すと件数ぶんクエリが増える
    @notices = Notice.recent.includes(:created_by).with_rich_text_content_and_embeds
    @notices = @notices.where(category: @category) if @category
  end

  def show
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
