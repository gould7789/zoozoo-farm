# 動物のプロフィール写真を削除するコントローラー
# 動物の編集と同じくAdmin専用
class AnimalPhotosController < ApplicationController
  before_action :require_admin
  before_action :set_animal

  def destroy
    # ジョブキューが永続化されていない（:async）ため同期で削除する。
    # purge_laterだと無料プランのインスタンスが眠った時点でジョブが失われ、
    # ストレージに孤児ファイルが残る。S3のDELETE1回なので待っても問題ない
    @animal.photo.purge
    redirect_to edit_zone_animal_path(@zone, @animal), notice: "사진을 삭제했습니다."
  end

  private

    # 館を経由して探す — URLの館と動物の組み合わせが食い違えば404にする
    def set_animal
      @zone   = Zone.find(params[:zone_id])
      @animal = @zone.animals.find(params[:animal_id])
    end
end
