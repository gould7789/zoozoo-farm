# お知らせ本文のリッチテキスト編集を検証する system spec
#
# ここで確かめたいのは2点だけ。
#   1. 本文に貼った画像がアップロード前にブラウザ側で縮小されること
#   2. 既定の window リスナーを止められていて、二重送信になっていないこと
#
# Trix のツールバーの見た目や文字装飾は目視に委ねる。
# 壊れたときに静かに壊れるのは上の2点で、どちらもDBを見ないと分からない。
require "rails_helper"

RSpec.describe "공지 리치텍스트", type: :system do
  let(:staff) { create(:user) }

  before do
    sign_in_as(staff)
    visit new_notice_path
  end

  # 縮小を検証するには fixture より大きい画像が要る。
  # ファイルを置くと数MBをリポジトリに入れることになるので、
  # ブラウザ側で生成して editor.insertFile に渡す。
  # 一様な塗りつぶしだとJPEGがほぼゼロまで潰れて縮小の効果が測れないため、
  # ランダムな矩形でノイズを入れる
  def insert_generated_image(width:, height:, type: "image/png")
    page.execute_script(<<~JS, width, height, type)
      const [ width, height, type ] = arguments
      const canvas = document.createElement("canvas")
      canvas.width = width
      canvas.height = height
      const context = canvas.getContext("2d")
      for (let i = 0; i < 400; i++) {
        context.fillStyle = `hsl(${Math.random() * 360}, 70%, 50%)`
        context.fillRect(Math.random() * width, Math.random() * height, 200, 200)
      }
      canvas.toBlob((blob) => {
        const name = "pasted." + type.split("/")[1]
        document.querySelector("trix-editor").editor.insertFile(new File([ blob ], name, { type }))
      }, type)
    JS
  end

  # figure.attachment はアップロードの「開始」時点でもう現れる。
  # そこで待ったつもりになると、POST がロールバックの後に着地して
  # 次のexampleの計測を壊す（実測で半分ほど落ちた）。
  # sgid が入るのはアップロードが完了して setAttributes が走った後なので、そこで待つ
  def wait_for_upload
    expect(page).to have_css("figure[data-trix-attachment*='sgid']", wait: 10)
  end

  def submit_and_take_blob
    fill_in_reliably "제목", with: "사진 공지"
    click_reliably "작성"
    expect(page).to have_current_path(notices_path)
    Notice.last.content.embeds.first.tap { |blob| blob.analyze unless blob.analyzed? }
  end

  # 縮小が不要なPNGまでJPEGに焼き直すと、ロゴやスクリーンショットの
  # 透過が黒く潰れる。現場はカカオトークの画像を貼るので
  # スクリーンショットが混じる
  it "縮小が要らない画像はPNGのまま保存される" do
    insert_generated_image(width: 400, height: 300)
    wait_for_upload

    blob = submit_and_take_blob
    expect(blob.content_type).to eq("image/png")
    expect(blob.metadata["width"]).to eq(400)
  end

  it "本文に貼った画像は1600pxに縮小されて1件だけ保存される" do
    # このexampleでアップロードされた blob だけを数える。
    # 単純な総数では2件になるが、2件目はアップロードではなく variant である。
    # 一覧を描画した時点で _blob.html.erb が 1200px の変換を要求し、
    # その結果が VariantRecord に添付された別の blob として入る。
    # 前のexampleの行が混ざるのも防ぐため created_at でも切る
    started_at = Time.current

    insert_generated_image(width: 3000, height: 2000)

    # ダイレクトアップロードの完了を待つ。完了すると attachment の
    # figure に sgid が入り、プログレス表示が消える
    wait_for_upload

    blob = submit_and_take_blob

    # blob の件数で見る。本文の embeds は sgid が1つしか残らないため、
    # 二重に送られていても1件に見えてしまう（実測で確認した）。
    # 既定の window リスナーが生きていると原本ぶんの blob が余分に作られる
    uploaded = ActiveStorage::Blob
      .where(created_at: started_at..)
      .where.not(id: ActiveStorage::Attachment.where(record_type: "ActiveStorage::VariantRecord").select(:blob_id))
    expect(uploaded.count).to eq(1)

    expect(blob.content_type).to eq("image/jpeg")
    expect(blob.metadata["width"]).to eq(1600)
    expect(blob.metadata["height"]).to eq(1067)
  end
end
