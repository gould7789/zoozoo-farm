# system spec用のドライバ設定
#
# CIのubuntu-latestにはChromeが入っており、selenium-webdriver 4の
# Selenium Managerがchromedriverを自動で用意するため追加の導入手順は要らない。
#
# 画面サイズは現場の主な利用環境（WindowsのデスクトップPC）に合わせる。
# 写真のアップロードはカカオトークで受け取った画像をPCから上げる経路が主で、
# モバイルは副次的な経路のため。
RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 900 ]
  end
end
