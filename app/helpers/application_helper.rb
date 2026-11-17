module ApplicationHelper
  # 하단 탭 네비게이션 링크의 속성
  # also_active_on: 하위 페이지에서도 활성으로 보일 경로 배열 (관리 허브용)
  # 클래스만 돌려주지 않는 이유 — aria-current 와 클래스가 같은 active 판정에서 나와야 한다. 따로 두면 한쪽만 고쳐져 「색은 켜졌는데 스크린리더는 모르는」 상태가 된다
  def nav_link_attrs(path, also_active_on: [])
    active = nav_active?(path, also_active_on)
    # border-t-2 를 base 에 둔다. 활성에만 주면 전환할 때 2px 밀린다
    base = "flex flex-col items-center justify-center gap-0.5 flex-1 py-2 " \
           "border-t-2 text-xs font-medium transition-colors"
    state = active ? "border-green-600 text-green-600"
                   : "border-transparent text-gray-500 hover:text-gray-700"

    { class: "#{base} #{state}", aria: { current: ("page" if active) } }
  end

  # 사이드바 네비게이션 링크의 속성
  def sidebar_link_attrs(path, also_active_on: [])
    active = nav_active?(path, also_active_on)
    base = "flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-colors w-full"
    state = active ? "bg-green-50 text-green-700" : "text-gray-700 hover:bg-gray-100 hover:text-gray-900"

    { class: "#{base} #{state}", aria: { current: ("page" if active) } }
  end

  # 하위 경로도 활성으로 본다 — /zones/1 에서 「관 목록」이 켜져 있어야 한다
  def nav_active?(path, also_active_on = [])
    ([ path ] + also_active_on).any? do |p|
      request.path == p || request.path.start_with?("#{p}/")
    end
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

  # 건강 기록 컨디션의 라벨과 배지 색 — [라벨, Tailwind 클래스]
  def health_condition_label(condition)
    {
      "normal"  => [ "정상", "bg-green-100 text-green-800" ],
      "caution" => [ "주의", "bg-yellow-100 text-yellow-800" ],
      "danger"  => [ "위험", "bg-red-100 text-red-800" ]
    }.fetch(condition.to_s, [ "—", "bg-gray-100 text-gray-700" ])
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
    }[category] || [ category, "bg-gray-100 text-gray-700" ]
  end
end
