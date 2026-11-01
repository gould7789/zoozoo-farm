# 전체 컨트롤러의 기반 클래스 — 인증 헬퍼와 xlsx 공통 스타일
# 판단 근거는 .claude/rules/notes/auth.md, notes/xlsx-export.md
class ApplicationController < ActionController::Base
  allow_browser versions: :modern

  # importmap 이 바뀌면 HTML 응답의 etag 를 무효화한다 — 캐시된 페이지가 낡은 JS 를 물지 않게
  stale_when_importmap_changes

  before_action :require_login

  helper_method :current_user, :logged_in?

  # DB 컬럼 범위를 넘는 수치가 들어온 경우 (integer overflow 등)
  rescue_from ActiveRecord::RangeError do
    redirect_back fallback_location: root_path,
                  alert: "입력값이 허용 범위를 초과했습니다. 숫자를 확인해주세요."
  end

  rescue_from ActiveRecord::RecordNotFound do
    redirect_to root_path, alert: "요청한 데이터를 찾을 수 없습니다."
  end

  # Strong Parameters 의 필수 키가 빠진 경우
  rescue_from ActionController::ParameterMissing do
    redirect_back fallback_location: root_path,
                  alert: "필수 항목이 누락됐습니다."
  end

  private

    def current_user
      @current_user ||= User.active.find_by(id: session[:user_id])
    end

    def logged_in?
      current_user.present?
    end

    def require_login
      redirect_to login_path, alert: "로그인이 필요합니다." unless logged_in?
    end

    def require_admin
      redirect_to root_path, alert: "권한이 없습니다." unless current_user&.admin?
    end

    # xlsx 내보내기 5개 컨트롤러가 공유하는 셀 스타일.
    # 서식 코드를 주지 않으면 Excel 에서 날짜가 시리얼 숫자로 보인다.
    # 자세한 것은 .claude/rules/notes/xlsx-export.md
    def xlsx_styles(workbook)
      {
        header:   workbook.styles.add_style(b: true, bg_color: "F3F4F6", border: { style: :thin, color: "D1D5DB" }, alignment: { horizontal: :center, vertical: :center }),
        text:     workbook.styles.add_style(alignment: { horizontal: :center, vertical: :center }),
        left:     workbook.styles.add_style(alignment: { horizontal: :left, vertical: :center }),
        date:     workbook.styles.add_style(format_code: "yyyy-mm-dd", alignment: { horizontal: :center, vertical: :center }),
        datetime: workbook.styles.add_style(format_code: "yyyy-mm-dd hh:mm", alignment: { horizontal: :center, vertical: :center }),
        money:    workbook.styles.add_style(format_code: "#,##0", alignment: { horizontal: :right, vertical: :center }),
        number:   workbook.styles.add_style(alignment: { horizontal: :center, vertical: :center })
      }
    end
end
