module ApplicationHelper
  # ナビゲーションリンクのCSSクラスを返す
  # 現在のパスに一致する場合はアクティブスタイルを適用する
  def nav_link_class(path)
    active = request.path == path || request.path.start_with?("#{path}/")
    base = "flex flex-col items-center gap-0.5 flex-1 py-2 text-xs font-medium transition-colors"
    color = active ? "text-blue-600" : "text-gray-400 hover:text-gray-600"
    "#{base} #{color}"
  end

  # サイドバーナビゲーションリンクのCSSクラスを返す
  def sidebar_link_class(path)
    active = request.path == path || request.path.start_with?("#{path}/")
    base = "flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-colors w-full"
    color = active ? "bg-blue-50 text-blue-700" : "text-gray-600 hover:bg-gray-100 hover:text-gray-900"
    "#{base} #{color}"
  end
end
