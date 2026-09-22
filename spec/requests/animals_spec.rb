# AnimalsControllerのリクエストテスト — 認証・権限制御を中心に検証する
require "rails_helper"

RSpec.describe "Animals", type: :request do
  let(:zone)  { create(:zone) }
  let(:admin) { create(:user, :admin) }
  let(:staff) { create(:user) }          # デフォルトはstaffロール

  describe "GET /zones/:zone_id/animals/:id" do
    let(:animal) { create(:animal, zone: zone) }

    # 未ログインはログインページへ強制リダイレクト
    context "未ログイン" do
      it "ログインページにリダイレクトする" do
        get zone_animal_path(zone, animal)
        expect(response).to redirect_to(login_path)
      end
    end

    # StaffもAdminも詳細ページは閲覧可能
    context "ログイン済み" do
      before { sign_in(staff) }

      it "200を返す" do
        get zone_animal_path(zone, animal)
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "GET /zones/:zone_id/animals/new" do
    # 動物の新規登録はAdmin専用 — Staffはルートへリダイレクト
    context "Staffがアクセス" do
      before { sign_in(staff) }

      it "ルートにリダイレクトする" do
        get new_zone_animal_path(zone)
        expect(response).to redirect_to(root_path)
      end
    end

    context "Adminがアクセス" do
      before { sign_in(admin) }

      it "200を返す" do
        get new_zone_animal_path(zone)
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "POST /zones/:zone_id/animals" do
    let(:valid_params) { { animal: { species: "インコ", gender: "unknown" } } }

    # 動物の作成はAdmin専用 — Staffはルートへリダイレクト
    context "Staffが投稿" do
      before { sign_in(staff) }

      it "ルートにリダイレクトする" do
        post zone_animals_path(zone), params: valid_params
        expect(response).to redirect_to(root_path)
      end
    end

    # Adminは動物を作成後に詳細ページへリダイレクト
    context "Adminが投稿" do
      before { sign_in(admin) }

      it "動物を作成してリダイレクトする" do
        post zone_animals_path(zone), params: valid_params
        expect(response).to redirect_to(zone_animal_path(zone, Animal.last))
      end
    end
  end

  describe "PATCH /zones/:zone_id/animals/:id" do
    let(:animal) { create(:animal, zone: zone) }
    let(:valid_params) { { animal: { species: "オウム" } } }

    # 更新はAdmin専用 — Staffはルートへリダイレクト
    context "Staffが更新しようとする" do
      before { sign_in(staff) }

      it "ルートにリダイレクトする" do
        patch zone_animal_path(zone, animal), params: valid_params
        expect(response).to redirect_to(root_path)
      end
    end

    # Adminは更新後に詳細ページへリダイレクト
    context "Adminが更新" do
      before { sign_in(admin) }

      it "動物情報を更新して詳細ページにリダイレクトする" do
        patch zone_animal_path(zone, animal), params: valid_params
        expect(response).to redirect_to(zone_animal_path(zone, animal))
        expect(animal.reload.species).to eq("オウム")
      end
    end
  end

  describe "DELETE /zones/:zone_id/animals/:id" do
    let(:animal) { create(:animal, zone: zone) }

    # 削除（論理削除）はAdmin専用 — Staffはルートへリダイレクト
    context "Staffが削除しようとする" do
      before { sign_in(staff) }

      it "ルートにリダイレクトする" do
        delete zone_animal_path(zone, animal)
        expect(response).to redirect_to(root_path)
      end
    end

    # Adminが削除するとactive=falseになり館ページへリダイレクト（実際のDELETEは行わない）
    context "Adminが削除" do
      before { sign_in(admin) }

      it "論理削除してゾーンページにリダイレクトする" do
        delete zone_animal_path(zone, animal)
        expect(response).to redirect_to(zone_path(zone))
        expect(animal.reload.active).to be false
      end
    end
  end

  describe "プロフィール写真" do
    let(:animal)     { create(:animal, zone: zone) }
    let(:photo_file) { fixture_file_upload("animal.jpg", "image/jpeg") }

    it "Adminが写真付きで登録できる" do
      sign_in(admin)
      expect {
        post zone_animals_path(zone), params: {
          animal: { species: "ラッコ", individual_count: 1, photo: photo_file }
        }
      }.to change(ActiveStorage::Attachment, :count).by(1)

      expect(Animal.find_by(species: "ラッコ").photo).to be_attached
    end

    # RenderのlibvipsはHEICを読めないため、保存させずに弾く。
    # content_typeは申告値ではなく実バイトから判定されるため実物のHEICを使う。
    it "HEICは拒否して登録されない" do
      sign_in(admin)
      expect {
        post zone_animals_path(zone), params: {
          animal: {
            species: "ラッコ",
            individual_count: 1,
            photo: fixture_file_upload("animal.heic", "image/heic")
          }
        }
      }.not_to change(Animal, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("HEIC")
    end

    # 配信はproxy経由 — redirectだとストレージのドメインへ302し、
    # CSPのimg_src（:self, :data）に阻まれる
    it "詳細ページがproxy経由のURLで画像を出力する" do
      animal.photo.attach(photo_file)
      sign_in(staff)

      get zone_animal_path(zone, animal)

      expect(response.body).to include("/rails/active_storage/representations/proxy/")
    end

    it "編集フォームに写真の入力欄と切り抜き用コントローラーが出る" do
      sign_in(admin)

      get edit_zone_animal_path(zone, animal)

      expect(response.body).to include("animal[photo]")
      expect(response.body).to include("photo-crop")
      # 切り抜き画面はdialogで出す
      expect(response.body).to include('data-photo-crop-target="dialog"')
    end

    # 保存前に選んだ写真を取り消すボタン — 新規登録でも出る。
    # サーバーには何も送らないためbutton型で、最初は隠しておきJSが表示する
    it "新規登録フォームにも選択取り消し用のボタンが隠れた状態で出る" do
      sign_in(admin)

      get new_zone_animal_path(zone)

      # 属性の並び順に依存しないようCSSセレクタで確認する
      assert_select 'button[type="button"][hidden][data-photo-crop-target="clear"][data-action="photo-crop#clear"]'
    end

    # 削除の動作そのものは spec/requests/animal_photos_spec.rb で検証する
    it "写真がある時だけ編集フォームに削除ボタンが出て、確認モーダルを経由する" do
      sign_in(admin)
      animal.photo.attach(photo_file)

      get edit_zone_animal_path(zone, animal)
      expect(response.body).to include(zone_animal_photo_path(zone, animal))
      expect(response.body).to include('data-turbo-confirm="사진을 삭제하시겠습니까?"')

      animal.photo.purge
      get edit_zone_animal_path(zone, animal)
      expect(response.body).not_to include(zone_animal_photo_path(zone, animal))
    end

    # アバターをタップすると原寸を見られる — modalは body 直下にレンダされる
    it "詳細ページに原寸表示モーダルが出力される" do
      animal.photo.attach(photo_file)
      sign_in(staff)

      get zone_animal_path(zone, animal)

      expect(response.body).to include("photo-modal")
    end
  end
end
