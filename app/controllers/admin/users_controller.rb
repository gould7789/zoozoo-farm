# Admin 전용 사용자 관리 — Staff 계정 생성·수정·퇴사 처리
# 판단 근거는 .claude/rules/notes/auth.md
class Admin::UsersController < ApplicationController
  before_action :require_admin
  before_action :set_user, only: [ :edit, :update, :destroy ]

  def index
    # 재직 중인 관리자/스태프와 퇴사자를 별도로 취득해 뷰에서 분리 표시
    @admins         = User.admin.where(active: true).order(:name)
    @staffs         = User.staff.where(active: true).order(:name)
    @inactive_users = User.where(active: false).order(:name)

    # 기록을 가진 사용자 ID 를 미리 모은다 — 삭제 버튼을 보일지 가르는 데 쓴다
    @user_ids_with_records = collect_user_ids_with_records(@admins + @staffs + @inactive_users)
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      redirect_to admin_members_path, notice: "계정을 생성했습니다."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def destroy
    # 자기 자신은 지울 수 없다
    if @user == current_user
      redirect_to admin_members_path, alert: "자기 자신은 삭제할 수 없습니다."
      return
    end

    # restrict_with_error 라 예외 없이 false 가 돌아온다.
    # 화면에서도 버튼을 감추지만, 직접 요청과 경합에 대한 최종 방어선으로 남긴다
    if @user.destroy
      redirect_to admin_members_path, notice: "계정을 삭제했습니다."
    else
      redirect_to admin_members_path,
                  alert: "작성한 기록이 있어 삭제할 수 없습니다. 퇴사 처리를 이용해주세요."
    end
  end

  def update
    if @user.update(user_update_params)
      redirect_to admin_members_path, notice: "계정 정보를 수정했습니다."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

    def set_user
      @user = User.find(params[:id])
    end

    # 기록을 1건 이상 가진 사용자 ID 를 Set 으로 돌려준다.
    # 사용자마다 세면 N+1 이라, 테이블마다 1쿼리(총 5쿼리)로 한 번에 모은다
    def collect_user_ids_with_records(users)
      ids = users.map(&:id)
      [ HealthRecord, FeedingRecord, Notice, SalesRecord, ExpenseRecord ]
        .flat_map { |klass| klass.where(created_by_id: ids).distinct.pluck(:created_by_id) }
        .to_set
    end

    # 신규 생성용 — 비밀번호 필수
    def user_params
      permitted = params.require(:user).permit(:name, :email, :password, :role, :position, :is_team_leader, :hired_on, :contract_ends_on)
      # 빈 문자열은 nil 로 — enum 에 빈 문자열을 넘기면 ArgumentError 가 된다
      permitted[:position] = nil if permitted[:position].blank?
      permitted
    end

    # 수정용 — 비밀번호는 선택(비우면 변경 안 함), 퇴사 처리(active)도 포함한다
    def user_update_params
      permitted = params.require(:user).permit(:name, :email, :password, :role, :active,
                                               :position, :is_team_leader, :hired_on, :contract_ends_on)
      # 마지막 관리자가 자기 권한을 잃으면 화면에서 되돌릴 방법이 없다
      if @user == current_user
        permitted.delete(:role)
        permitted.delete(:active)
      end
      # 비밀번호가 비어 있으면 갱신하지 않는다
      permitted.delete(:password) if permitted[:password].blank?
      # 빈 문자열은 nil 로
      permitted[:position] = nil if permitted[:position].blank?
      permitted
    end
end
