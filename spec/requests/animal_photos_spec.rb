# AnimalPhotosControllerのリクエストテスト — プロフィール写真の削除と権限制御を検証する
require "rails_helper"

RSpec.describe "AnimalPhotos", type: :request do
  let(:zone)   { create(:zone) }
  let(:admin)  { create(:user, :admin) }
  let(:staff)  { create(:user) }
  let(:animal) { create(:animal, zone: zone) }

  before do
    animal.photo.attach(fixture_file_upload("animal.jpg", "image/jpeg"))
  end

  describe "DELETE /zones/:zone_id/animals/:animal_id/photo" do
    context "未ログイン" do
      it "ログインページにリダイレクトし、写真は残る" do
        delete zone_animal_photo_path(zone, animal)

        expect(response).to redirect_to(login_path)
        expect(animal.reload.photo).to be_attached
      end
    end

    # 動物の編集はAdmin専用 — 写真の削除も同じ権限に揃える
    context "Staffが削除しようとする" do
      before { sign_in(staff) }

      it "ルートにリダイレクトし、写真は残る" do
        delete zone_animal_photo_path(zone, animal)

        expect(response).to redirect_to(root_path)
        expect(animal.reload.photo).to be_attached
      end
    end

    context "Adminが削除" do
      before { sign_in(admin) }

      it "写真を外して編集ページに戻る" do
        delete zone_animal_photo_path(zone, animal)

        expect(response).to redirect_to(edit_zone_animal_path(zone, animal))
        expect(animal.reload.photo).not_to be_attached
      end

      # ジョブキューが永続化されていない（:async）ため同期で消す。
      # 非同期だとインスタンスが眠った時点でジョブが失われ、ストレージに孤児が残る
      it "blobもその場で消える" do
        blob_id = animal.photo.blob.id

        delete zone_animal_photo_path(zone, animal)

        expect(ActiveStorage::Blob.exists?(blob_id)).to be false
      end

      # 館と動物の組み合わせが食い違えばRecordNotFound。
      # ApplicationControllerのrescue_fromでルートへリダイレクトされる
      it "他の館の動物は削除できない" do
        other_animal = create(:animal)
        other_animal.photo.attach(fixture_file_upload("animal.jpg", "image/jpeg"))

        delete zone_animal_photo_path(zone, other_animal)

        expect(response).to redirect_to(root_path)
        expect(other_animal.reload.photo).to be_attached
      end
    end
  end
end
