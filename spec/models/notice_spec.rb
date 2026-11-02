require "rails_helper"

RSpec.describe Notice, type: :model do
  describe "검증" do
    it { is_expected.to validate_presence_of(:category) }

    it "content 가 비어 있으면 무효" do
      notice = build(:notice, content: "")
      expect(notice).to be_invalid
      expect(notice.errors[:content]).to be_present
    end

    it "content 가 있으면 유효" do
      expect(build(:notice, content: "<div>공지</div>")).to be_valid
    end
  end

  describe "리치텍스트" do
    # 본문은 notices 가 아니라 action_text_rich_texts 에 들어간다 (notes/notice.md)
    it "content 는 ActionText::RichText 로 저장된다" do
      notice = create(:notice, content: "<div>단수 안내</div>")

      rich_text = ActionText::RichText.find_by(
        record_type: "Notice", record_id: notice.id, name: "content"
      )
      expect(rich_text).to be_present
      expect(rich_text.body.to_s).to include("단수 안내")
    end

    it "notices.body 컬럼과 별개로 공존한다" do
      # 이관 기간 동안 body 를 보관용으로 남긴다. 둘이 독립해서 읽혀야 한다.
      notice = create(:notice, content: "<div>새 본문</div>")
      notice.update_column(:body, "지난 평문")

      expect(notice.reload.body).to eq("지난 평문")
      expect(notice.content.to_s).to include("새 본문")
    end
  end

  describe "임베드 이미지 검증" do
    let(:notice) { build(:notice) }

    # identify: false 가 없으면 실제 바이트에서 content_type 을 다시 판정해
    # HEIC 로 위장시킬 수 없다 — 위장 자체를 만들기 위한 장치다
    def attach_embed(filename:, content_type:)
      blob = ActiveStorage::Blob.create_and_upload!(
        io: Rails.root.join("spec/fixtures/files/animal.jpg").open,
        filename: filename,
        content_type: content_type,
        identify: false
      )
      notice.content = ActionText::Content.new.append_attachables(blob)
      blob
    end

    it "지원 형식 이미지는 통과시킨다" do
      attach_embed(filename: "photo.jpg", content_type: "image/jpeg")
      expect(notice).to be_valid
    end

    it "확장자를 위장한 파일을 내용으로 판정해 거부한다" do
      path = Rails.root.join("spec/fixtures/files/animal.heic")
      blob = ActiveStorage::Blob.create_before_direct_upload!(
        filename: "photo.jpg", byte_size: path.size,
        checksum: ActiveStorage::Blob.new.send(:compute_checksum_in_chunks, path.open),
        content_type: "image/jpeg"
      )
      blob.upload_without_unfurling(path.open)
      notice.content = ActionText::Content.new.append_attachables(blob)

      expect(notice).not_to be_valid
      expect(notice.errors[:content].join).to include("JPG")
    end

    it "외부 URL 첨부를 거부한다" do
      notice.content = <<~HTML
        <div>본문<action-text-attachment url="https://evil.example/track.png"
          content-type="image/png" width="1" height="1"></action-text-attachment></div>
      HTML

      expect(notice).not_to be_valid
      expect(notice.errors[:content]).to be_present
    end

    it "지원하지 않는 형식은 거부한다" do
      attach_embed(filename: "photo.heic", content_type: "image/heic")
      expect(notice).not_to be_valid
      expect(notice.errors[:content]).to be_present
    end

    it "상한을 넘는 크기는 거부한다" do
      blob = attach_embed(filename: "photo.jpg", content_type: "image/jpeg")
      allow_any_instance_of(ActiveStorage::Blob)
        .to receive(:byte_size).and_return(Notice::MAX_EMBED_BYTES + 1)
      expect(blob).to be_present
      expect(notice).not_to be_valid
      expect(notice.errors[:content].join).to include("15MB")
    end
  end

  describe "#excerpt" do
    def excerpt_of(html)
      build(:notice, content: html).excerpt
    end

    it "문단 경계를 공백으로 만든다" do
      expect(excerpt_of("<div>테스트 내용</div><div>굿</div><div>응?</div>"))
        .to eq("테스트 내용 굿 응?")
    end

    it "br 도 공백으로 만든다" do
      expect(excerpt_of("<p>1행<br>2행</p>")).to eq("1행 2행")
    end

    it "실체 참조를 되돌린다" do
      expect(excerpt_of("<div>a &amp; b &lt;c&gt;</div>")).to eq("a & b <c>")
    end

    it "첨부는 발췌에 내지 않는다" do
      blob = ActiveStorage::Blob.create_and_upload!(
        io: Rails.root.join("spec/fixtures/files/animal.jpg").open,
        filename: "a.jpg", content_type: "image/jpeg"
      )
      content = ActionText::Content.new("<div>본문</div>").append_attachables(blob)

      expect(build(:notice, content: content).excerpt).to eq("본문")
    end

    it "긴 본문은 잘라낸다" do
      expect(excerpt_of("<div>#{'가' * 200}</div>").length).to eq(80)
    end
  end

  describe "연관" do
    it { is_expected.to belong_to(:created_by).class_name("User") }
  end

  describe "enum" do
    it "category enum 이 올바르게 정의돼 있다" do
      expect(Notice.categories).to eq({
        "general"      => 0,
        "lovebird"     => 1,
        "parrot"       => 2,
        "reptile"      => 3,
        "small_animal" => 4,
        "outdoor"      => 5,
        "isolation"    => 6
      })
    end
  end

  describe "스코프" do
    it ".recent 는 작성 일시 내림차순으로 반환한다" do
      user  = create(:user)
      older = create(:notice, created_by: user, created_at: 2.days.ago)
      newer = create(:notice, created_by: user, created_at: 1.hour.ago)

      expect(Notice.recent.first).to eq(newer)
      expect(Notice.recent.last).to eq(older)
    end
  end

  describe "DB 제약" do
    it_behaves_like "DB 가 범위 밖 enum 값을 거부한다", :category, 9
  end
end
