# 본인 기록 또는 Admin 만 수정·삭제를 허용한다
# HealthRecords / FeedingRecords / Notices 세 컨트롤러가 공유한다
module OwnerRestriction
  extend ActiveSupport::Concern

  private

    def require_owner(record)
      return if current_user.admin?
      redirect_to root_path, alert: "권한이 없습니다." unless record.created_by_id == current_user.id
    end
end
