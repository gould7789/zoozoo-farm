require "rails_helper"

RSpec.describe Notice, type: :model do
  describe "バリデーション" do
    it { is_expected.to validate_presence_of(:category) }

    it "contentが空なら無効" do
      notice = build(:notice, content: "")
      expect(notice).to be_invalid
      expect(notice.errors[:content]).to be_present
    end

    it "contentがあれば有効" do
      expect(build(:notice, content: "<div>お知らせ</div>")).to be_valid
    end
  end

  describe "リッチテキスト" do
    # has_rich_text は notices テーブルではなく action_text_rich_texts に保存する。
    # name カラムに "content" が入り、record_type/record_id で所有者を指す。
    it "contentはActionText::RichTextとして保存される" do
      notice = create(:notice, content: "<div>단수 안내</div>")

      rich_text = ActionText::RichText.find_by(
        record_type: "Notice", record_id: notice.id, name: "content"
      )
      expect(rich_text).to be_present
      expect(rich_text.body.to_s).to include("단수 안내")
    end

    it "noticesテーブルのbodyカラムとは別物として共存する" do
      # 移行期間中はbodyを保管用として残す。両方が独立して読める必要がある。
      notice = create(:notice, content: "<div>新しい本文</div>")
      notice.update_column(:body, "古い平文")

      expect(notice.reload.body).to eq("古い平文")
      expect(notice.content.to_s).to include("新しい本文")
    end
  end

  describe "埋め込み画像の検証" do
    # 本文の添付はダイレクトアップロードで入るため、フォームの検証を通らない。
    # 保存時にモデル側で止める
    let(:notice) { build(:notice) }

    # identify: false を付けるのは、付けないと実ファイルのバイト列から
    # content_type を判定し直され、HEICを装わせられないため
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

    it "対応形式の画像は通す" do
      attach_embed(filename: "photo.jpg", content_type: "image/jpeg")
      expect(notice).to be_valid
    end

    # ダイレクトアップロードはブラウザの申告した content_type をそのまま保存する。
    # 拡張子と申告を image/jpeg に付け替えても、中身を読んで弾けること
    it "拡張子を偽装したファイルを中身で判定して拒否する" do
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

    # 本文のHTMLを直接組み立てれば、Active Storage を通さない添付も作れる。
    # <action-text-attachment url="..."> は ActionText::Attachables::RemoteImage になり、
    # blob ではないので形式検証を素通りして <img src="外部URL"> として描画される。
    # 今は CSP の img-src が外部を弾くが、CSP を緩めた瞬間に生き返る穴なので塞ぐ
    it "外部URLの添付を拒否する" do
      notice.content = <<~HTML
        <div>본문<action-text-attachment url="https://evil.example/track.png"
          content-type="image/png" width="1" height="1"></action-text-attachment></div>
      HTML

      expect(notice).not_to be_valid
      expect(notice.errors[:content]).to be_present
    end

    it "対応していない形式は拒否する" do
      attach_embed(filename: "photo.heic", content_type: "image/heic")
      expect(notice).not_to be_valid
      expect(notice.errors[:content]).to be_present
    end

    it "上限を超えるサイズは拒否する" do
      blob = attach_embed(filename: "photo.jpg", content_type: "image/jpeg")
      allow_any_instance_of(ActiveStorage::Blob)
        .to receive(:byte_size).and_return(Notice::MAX_EMBED_BYTES + 1)
      expect(blob).to be_present
      expect(notice).not_to be_valid
      expect(notice.errors[:content].join).to include("15MB")
    end
  end

  describe "#excerpt" do
    # 一覧に出す2行の抜粋。本文のHTMLから作る。
    # to_plain_text は添付を1件ずつ引き直してN+1になるので使わない
    def excerpt_of(html)
      build(:notice, content: html).excerpt
    end

    # strip_tags はブロックの境目に空白を入れない。
    # そのまま剥がすと「テスト内容」「굿」「응?」が繋がって読めなくなる
    it "段落の境目を空白にする" do
      expect(excerpt_of("<div>테스트 내용</div><div>굿</div><div>응?</div>"))
        .to eq("테스트 내용 굿 응?")
    end

    it "brも空白にする" do
      expect(excerpt_of("<p>1행<br>2행</p>")).to eq("1행 2행")
    end

    # 平文から移行したお知らせは本文に &lt; などが入っている。
    # 実体参照のままERBに渡すと二重エスケープされ、画面に &lt; と出る
    it "実体参照を戻す" do
      expect(excerpt_of("<div>a &amp; b &lt;c&gt;</div>")).to eq("a & b <c>")
    end

    it "添付は抜粋に出さない" do
      blob = ActiveStorage::Blob.create_and_upload!(
        io: Rails.root.join("spec/fixtures/files/animal.jpg").open,
        filename: "a.jpg", content_type: "image/jpeg"
      )
      content = ActionText::Content.new("<div>본문</div>").append_attachables(blob)

      expect(build(:notice, content: content).excerpt).to eq("본문")
    end

    it "長い本文は切り詰める" do
      expect(excerpt_of("<div>#{'가' * 200}</div>").length).to eq(80)
    end
  end

  describe "アソシエーション" do
    it { is_expected.to belong_to(:created_by).class_name("User") }
  end

  describe "enum" do
    it "categoryのenumが正しく定義されている" do
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

  describe "スコープ" do
    it ".recentは作成日時の降順で返す" do
      user  = create(:user)
      older = create(:notice, created_by: user, created_at: 2.days.ago)
      newer = create(:notice, created_by: user, created_at: 1.hour.ago)

      expect(Notice.recent.first).to eq(newer)
      expect(Notice.recent.last).to eq(older)
    end
  end
end
