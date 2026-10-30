# お知らせモデル — 全体および各館向けの通知を管理する
class Notice < ApplicationRecord
  # 本文に埋め込む画像で許可する形式。Animalの写真と同じ理由で、
  # RenderのlibvipsはHEICを読めず variant 生成が失敗する。
  ALLOWED_EMBED_TYPES = %w[ image/jpeg image/png image/webp ].freeze
  # ブラウザ側で1600pxに縮小しているので通常は数百KBで届く。
  # JSが失敗した場合の安全網
  MAX_EMBED_BYTES = 15.megabytes

  # 作成者
  belongs_to :created_by, class_name: "User"

  # 本文のリッチテキスト。
  # :body ではなく :content にしているのは、has_rich_text が class_eval で
  # モデルクラスに直接アクセサを定義するため、:body だと既存の body カラムを
  # 覆い隠してしまうからである。移行期間中は両方を独立して読む必要がある。
  has_rich_text :content

  # カテゴリ enum（0=全体, 1=コザクラ館, 2=オウム館, 3=爬虫類館, 4=ミニ動物館, 5=屋外体験館, 6=隔離室）
  enum :category, {
    general:      0,
    lovebird:     1,
    parrot:       2,
    reptile:      3,
    small_animal: 4,
    outdoor:      5,
    isolation:    6
  }

  # 題名・本文・カテゴリは必須
  validates :title,    presence: true, length: { maximum: 100 }
  validates :content,  presence: true
  validates :category, presence: true
  # 埋め込み画像はダイレクトアップロードで入るためフォームの検証を通らない。
  # 添付はvalidatesで扱えないのでカスタム検証で行う
  validate :embeds_must_be_supported_images

  # 最新投稿順に並べるスコープ
  scope :recent, -> { order(created_at: :desc) }

  # 一覧に出す抜粋。見出しの下の2行なので、タグも画像も要らない。
  #
  # to_plain_text ではなく HTML からタグを剥がす。to_plain_text は添付を
  # 1件ずつ sgid から引き直して平文表現を作るため、一覧で使うと
  # お知らせの数だけクエリが増える（実測で1件あたり2クエリ）
  def excerpt(length: 80)
    ActionController::Base.helpers.strip_tags(content.body.to_html).squish.truncate(length)
  end

  # 本文に貼られた画像の枚数。0なら一覧にバッジを出さない。
  #
  # body からではなく embeds から数える。body.attachables は sgid を1件ずつ
  # GlobalID で引き直すため、一覧で使うとお知らせの数だけクエリが増える。
  # embeds は with_rich_text_content_and_embeds で先読みされる
  def photo_count
    content.embeds.size
  end

  private

    # 本文に貼られた画像の形式とサイズを検証する。
    # content.embeds はリッチテキストの保存時に埋まるため、検証の時点ではまだ空。
    # 本文のHTMLから直接 attachable を取り出す。
    def embeds_must_be_supported_images
      return if content.blank?

      attachables = content.body.attachables

      # エディタが作る添付は必ず ActiveStorage::Blob になる。
      # それ以外が混ざるのは本文のHTMLを手で組み立てた場合で、たとえば
      # <action-text-attachment url="..."> は RemoteImage になり、
      # blob を対象にした下の検証を素通りして <img src="外部URL"> として描画される。
      # CSP の img-src が外部を弾くので今は実害が無いが、
      # 防御を1枚に頼る形になるのでここで弾く
      unless attachables.all? { |attachable| attachable.is_a?(ActiveStorage::Blob) }
        errors.add(:content, :unsupported_attachment)
        return
      end

      attachables.each do |blob|
        # content_type はブラウザの申告ではなく実体から判定された値である。
        # ActiveStorage::Attached::Changes が添付を組み立てる時点で
        # identify_without_saving を通すため、ここに来るまでに確定している。
        # Rails内部の動作に依存するので、偽装ファイルのspecで固定してある
        errors.add(:content, :unsupported_type) unless ALLOWED_EMBED_TYPES.include?(blob.content_type)
        errors.add(:content, :too_large, limit: MAX_EMBED_BYTES / 1.megabyte) if blob.byte_size > MAX_EMBED_BYTES
      end
    end
end
