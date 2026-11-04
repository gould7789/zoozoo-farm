module ApplicationHelper
  # 하단 탭 네비게이션 링크의 CSS 클래스
  # also_active_on: 하위 페이지에서도 활성으로 보일 경로 배열 (관리 허브용)
  def nav_link_class(path, also_active_on: [])
    active = request.path == path ||
             request.path.start_with?("#{path}/") ||
             also_active_on.any? { |p| request.path == p || request.path.start_with?("#{p}/") }
    base = "flex flex-col items-center gap-0.5 flex-1 py-2 text-xs font-medium transition-colors"
    color = active ? "text-green-600" : "text-gray-400 hover:text-gray-600"
    "#{base} #{color}"
  end

  # 사이드바 네비게이션 링크의 CSS 클래스
  def sidebar_link_class(path)
    active = request.path == path || request.path.start_with?("#{path}/")
    base = "flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-colors w-full"
    color = active ? "bg-green-50 text-green-700" : "text-gray-600 hover:bg-gray-100 hover:text-gray-900"
    "#{base} #{color}"
  end

  # shared/_action_menu 안 항목의 CSS 클래스 — 링크와 button_to 가 같은 모양이어야 한다
  def menu_item_class
    "flex items-center gap-2 w-full px-4 py-2.5 text-sm text-gray-700 hover:bg-gray-50 text-left transition-colors"
  end

  # 내보낸 사유의 화면 라벨과 배지 색
  def animal_exit_label(reason)
    {
      "deceased"    => [ "폐사", "bg-gray-200 text-gray-700" ],
      "transferred" => [ "분양", "bg-blue-100 text-blue-700" ]
    }.fetch(reason.to_s, [ "내보냄", "bg-gray-200 text-gray-700" ])
  end

  # 공지 카테고리의 라벨과 색 클래스 — [라벨, Tailwind 클래스]
  def notice_category_label(category)
    {
      "general"      => [ "전체",          "bg-blue-100 text-blue-700" ],
      "lovebird"     => [ "사랑새관",       "bg-pink-100 text-pink-700" ],
      "parrot"       => [ "앵무새관",       "bg-green-100 text-green-700" ],
      "reptile"      => [ "파충류관",       "bg-yellow-100 text-yellow-700" ],
      "small_animal" => [ "미니동물관",     "bg-orange-100 text-orange-700" ],
      "outdoor"      => [ "야외동물체험관", "bg-teal-100 text-teal-700" ],
      "isolation"    => [ "격리실",         "bg-red-100 text-red-700" ]
    }[category] || [ category, "bg-gray-100 text-gray-600" ]
  end
end
