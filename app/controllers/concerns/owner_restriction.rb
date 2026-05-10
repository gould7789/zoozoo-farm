# 本人記録またはAdminのみ編集・削除を許可するConcern
# HealthRecords / FeedingRecords / Notices の3コントローラーで共通利用
module OwnerRestriction
  extend ActiveSupport::Concern

  private

    def require_owner(record)
      return if current_user.admin?
      redirect_to root_path, alert: "권한이 없습니다." unless record.created_by_id == current_user.id
    end
end
