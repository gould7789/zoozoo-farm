# 공지 CRUD
# 전체 액션에 로그인 필수, 수정과 삭제는 본인 기록만 (Admin 은 타인 기록도 조작 가능)
class NoticesController < ApplicationController
  include OwnerRestriction

  # 본문 에디터의 다이렉트 업로드는 서명된 URL 로 직접 PUT 한다.
  # connect_src 를 안 쓰면 default_src :self 가 적용돼 막힌다.
  # 전체가 아니라 이 컨트롤러에만 붙이는 이유는, 전체에 두면 비로그인으로 보이는
  # 로그인 화면에도 스토리지 호스트명이 실리기 때문이다.
  #
  # 허용 범위는 오리진(scheme://host)까지이고 경로는 붙이지 않는다.
  # 경로를 붙이면 완전 일치가 요구된다 — 자세한 것은 .claude/rules/notes/notice.md
  #
  # 개발과 테스트는 Disk 서비스라 같은 오리진이므로 이게 없어도 안 떨어진다.
  # 운영에서만 듣는다. ENV 가 없는 환경(CI)에서는 빈 배열이 된다
  STORAGE_ORIGIN = begin
    endpoint = ENV["SUPABASE_S3_ENDPOINT"]
    if endpoint.present?
      uri = URI.parse(endpoint)
      # 기본 포트는 쓰지 않는다. :443 을 붙여도 명세상 일치하지만 헤더만 읽기 어려워진다
      origin = +"#{uri.scheme}://#{uri.host}"
      origin << ":#{uri.port}" unless uri.port == uri.default_port
      [ origin ]
    else
      []
    end
  rescue URI::InvalidURIError
    []
  end.freeze

  content_security_policy do |policy|
    policy.connect_src :self, *STORAGE_ORIGIN
  end

  before_action :set_notice,                    only: [ :show, :edit, :update, :destroy ]
  before_action -> { require_owner(@notice) },  only: [ :edit, :update, :destroy ]

  def index
    @category = Notice.categories.key?(params[:category]) ? params[:category] : nil

    # 목록은 발췌와 사진 수만 내보내지만 둘 다 본문을 읽어야 한다.
    # with_rich_text_content_and_embeds 를 빼면 건수만큼 쿼리가 는다
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
      # :body 가 아니라 :content — 본문은 notices.body 가 아니라
      # action_text_rich_texts 에 들어간다
      params.require(:notice).permit(:category, :title, :content)
    end
end
