# ZonesControllerのリクエストテスト — 認証制御を中心に検証する
require "rails_helper"

RSpec.describe "Zones", type: :request do
  def query_count
    count = 0
    sub = ActiveSupport::Notifications.subscribe("sql.active_record") do |_, _, _, _, payload|
      count += 1 unless payload[:name].to_s =~ /SCHEMA|TRANSACTION/
    end
    begin
      yield
    ensure
      # ensureが無いと、ブロックが例外を投げた時に購読が残り
      # 以降のテストの計測値が狂う
      ActiveSupport::Notifications.unsubscribe(sub)
    end
    count
  end

  describe "GET /zones" do
    # 未ログインはログインページへ強制リダイレクト
    context "未ログイン" do
      it "ログインページにリダイレクトする" do
        get zones_path
        expect(response).to redirect_to(login_path)
      end
    end

    # ログイン済みは正常表示
    context "ログイン済み" do
      before { sign_in(create(:user)) }

      it "200を返す" do
        get zones_path
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "GET /zones/:id" do
    let(:zone) { create(:zone) }

    # 未ログインはログインページへ強制リダイレクト
    context "未ログイン" do
      it "ログインページにリダイレクトする" do
        get zone_path(zone)
        expect(response).to redirect_to(login_path)
      end
    end

    # ログイン済みは正常表示
    context "ログイン済み" do
      before { sign_in(create(:user)) }

      it "200を返す" do
        get zone_path(zone)
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "ホームの最新お知らせ" do
    let(:staff) { create(:user) }

    # 本文の保存先を変えたとき、ここの描画を直し忘れると行が空のまま出る。
    # notices一覧と違ってspecが無かった
    it "題名を表示する" do
      create(:notice, created_by: staff, title: "급수대 점검 예정")
      sign_in(staff)
      get zones_path
      expect(response.body).to include("급수대 점검 예정")
    end

    it "お知らせが増えてもクエリ数が増えない" do
      sign_in(staff)
      create(:notice, created_by: staff, title: "하나")
      few = query_count { get zones_path }

      3.times { |i| create(:notice, created_by: staff, title: "제목#{i}") }
      many = query_count { get zones_path }

      expect(many).to eq(few)
    end
  end

  describe "一覧のサムネイル" do
    let(:zone) { create(:zone) }

    def create_animal_with_photo(category: nil)
      create(:animal, zone: zone, animal_category: category).tap do |animal|
        animal.photo.attach(fixture_file_upload("animal.jpg", "image/jpeg"))
      end
    end

    before { sign_in(create(:user)) }

    it "写真がある動物はproxy経由のサムネイルを出す" do
      create_animal_with_photo

      get zone_path(zone)

      expect(response.body).to include("/rails/active_storage/representations/proxy/")
    end

    # 添付のプリロードが無いと動物ごとにクエリが増える
    it "動物が増えてもクエリ数が増えない" do
      3.times { create_animal_with_photo }
      few = query_count { get zone_path(zone) }

      7.times { create_animal_with_photo(category: create(:animal_category, zone: zone)) }
      many = query_count { get zone_path(zone) }

      expect(many).to eq(few)
    end

    # @animals_by_categoryを作る箇所はzones#showとanimal_categoriesの2つある。
    # こちらを直し忘れると、カテゴリ操作後の再描画でのみN+1が出る。
    # 普段は見えず特定の操作の後だけ現れるため、最も気づきにくい
    it "カテゴリ操作後の再描画でもクエリ数が増えない" do
      sign_in(create(:user, :admin))
      # トグル対象とは別に、未分類の動物を置く。
      # トグルするとそのカテゴリは非表示になり所属動物がアコーディオンから消えるため、
      # トグル対象に動物を入れると写真を参照するコードまで届かない
      toggled = create(:animal_category, zone: zone, hidden: false)
      # Acceptヘッダが無いとformat.htmlに落ちてリダイレクトされ、
      # アコーディオンが描画されないまま通ってしまう
      turbo = { headers: { "Accept" => "text/vnd.turbo-stream.html" } }

      3.times { create_animal_with_photo }
      few = query_count { patch toggle_zone_animal_category_path(zone, toggled), **turbo }

      7.times { create_animal_with_photo }
      many = query_count { patch toggle_zone_animal_category_path(zone, toggled), **turbo }

      expect(many).to eq(few)
    end
  end
end
