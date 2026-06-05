module ApplicationHelper
  # ナビゲーションリンクのCSSクラスを返す
  # also_active_on: サブページでもアクティブにしたいパスの配列（管理ハブ用）
  def nav_link_class(path, also_active_on: [])
    active = request.path == path ||
             request.path.start_with?("#{path}/") ||
             also_active_on.any? { |p| request.path == p || request.path.start_with?("#{p}/") }
    base = "flex flex-col items-center gap-0.5 flex-1 py-2 text-xs font-medium transition-colors"
    color = active ? "text-green-600" : "text-gray-400 hover:text-gray-600"
    "#{base} #{color}"
  end

  # サイドバーナビゲーションリンクのCSSクラスを返す
  def sidebar_link_class(path)
    active = request.path == path || request.path.start_with?("#{path}/")
    base = "flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-colors w-full"
    color = active ? "bg-green-50 text-green-700" : "text-gray-600 hover:bg-gray-100 hover:text-gray-900"
    "#{base} #{color}"
  end

  # お知らせカテゴリのラベルと色クラスを返す — [ラベル文字列, Tailwindクラス]
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
