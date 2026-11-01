# 공지 본문 리치텍스트 편집 — 확인하는 건 두 가지다.
#   1. 본문에 붙인 이미지가 올리기 전에 브라우저에서 줄어드는가
#   2. 기본 window 리스너를 멈춰 두 벌 올라가지 않는가
#
# 툴바 모양과 글자 장식은 목시에 맡긴다. 조용히 깨지는 건 위 두 가지이고
# 둘 다 DB 를 봐야 알 수 있다. 축소 자체의 판단은 .claude/rules/notes/notice.md
require "rails_helper"

RSpec.describe "공지 리치텍스트", type: :system do
  let(:staff) { create(:user) }

  before do
    sign_in_as(staff)
    visit new_notice_path
  end

  # 축소를 검증하려면 fixture 보다 큰 이미지가 필요하다. 파일로 두면 수MB 를
  # 저장소에 넣게 되므로 브라우저에서 만들어 editor.insertFile 에 넘긴다.
  # 단색으로 칠하면 JPEG 이 거의 0까지 뭉개져 효과를 못 재므로 무작위 사각형으로 노이즈를 넣는다
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

  # figure.attachment 는 업로드 「시작」 시점에 이미 나타난다. 거기서 기다린 줄 알면
  # POST 가 롤백 뒤에 착지해 다음 example 의 측정을 깬다(실측으로 절반쯤 떨어졌다).
  # sgid 는 업로드가 끝나고 setAttributes 가 돈 뒤에 들어가므로 그걸 기다린다
  def wait_for_upload
    expect(page).to have_css("figure[data-trix-attachment*='sgid']", wait: 10)
  end

  def submit_and_take_blob
    fill_in_reliably "제목", with: "사진 공지"
    click_reliably "작성"
    expect(page).to have_current_path(notices_path)
    Notice.last.content.embeds.first.tap { |blob| blob.analyze unless blob.analyzed? }
  end

  # 축소가 필요 없는 PNG 까지 JPEG 로 다시 구우면 투명이 검게 뭉개진다.
  # 현장은 카카오톡 이미지를 붙이므로 스크린샷이 섞인다
  it "축소가 필요 없는 이미지는 PNG 그대로 저장된다" do
    insert_generated_image(width: 400, height: 300)
    wait_for_upload

    blob = submit_and_take_blob
    expect(blob.content_type).to eq("image/png")
    expect(blob.metadata["width"]).to eq(400)
  end

  it "본문에 붙인 이미지는 1600px 로 줄어 1건만 저장된다" do
    # 이 example 에서 올라간 blob 만 센다. 단순 총수로는 2건이 되는데
    # 2건째는 업로드가 아니라 variant 다 — 목록을 그릴 때 _blob.html.erb 가
    # 1200px 변환을 요구하고, 그 결과가 VariantRecord 에 붙은 다른 blob 으로 들어간다.
    # 앞 example 의 행이 섞이는 것도 막으려 created_at 으로도 자른다
    started_at = Time.current

    insert_generated_image(width: 3000, height: 2000)

    # 다이렉트 업로드 완료를 기다린다 — figure 에 sgid 가 들어가고 진행 표시가 사라진다
    wait_for_upload

    blob = submit_and_take_blob

    # blob 건수로 본다. 본문의 embeds 는 sgid 가 하나만 남아 두 벌 보내져도
    # 1건으로 보인다(실측으로 확인했다). 기본 window 리스너가 살아 있으면
    # 원본 몫의 blob 이 하나 더 생긴다
    uploaded = ActiveStorage::Blob
      .where(created_at: started_at..)
      .where.not(id: ActiveStorage::Attachment.where(record_type: "ActiveStorage::VariantRecord").select(:blob_id))
    expect(uploaded.count).to eq(1)

    expect(blob.content_type).to eq("image/jpeg")
    expect(blob.metadata["width"]).to eq(1600)
    expect(blob.metadata["height"]).to eq(1067)
  end
end
