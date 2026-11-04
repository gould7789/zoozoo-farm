require "rails_helper"

# 화면 텍스트의 회색은 3단계만 쓴다. 판단 근거는 .claude/rules/notes/color.md
#
# spec/views 가 아니라 spec/lint 에 두는 이유 — 화면을 렌더하지 않는다.
# 소스를 읽어 금지 토큰을 세는 린트다. ERB 린터가 이 저장소에 없어 RSpec 으로 쓴다
RSpec.describe "색 규율" do
  # 폐기한 단계 → 대신 쓸 것
  RETIRED_GRAYS = {
    "300" => "500",
    "400" => "500",
    "600" => "700",
    "800" => "900"
  }.freeze

  # 엔트리 CSS 도 본다 — Trix 처럼 Tailwind 로 못 닿는 자리는 var(--color-gray-N) 을 쓴다
  SCANNED = %w[app/views app/helpers app/assets/tailwind].freeze

  def source_files
    Dir.glob(SCANNED.map { |d| Rails.root.join(d, "**", "*") }).select { |p| File.file?(p) }
  end

  # CSS 쪽은 「글자색」만 본다. border-color·background 의 회색은 이 규칙의 대상이 아니다
  # (카드 200 / 입력창 300 으로 이미 역할이 갈려 있다)
  def css_text_color(token)
    /(?<![-\w])color:\s*var\(--color-gray-#{token}\)/
  end

  # hover:text-gray-600 같은 변형과 CSS 변수를 둘 다 잡는다
  def offenses(token)
    pattern = Regexp.union(/\btext-gray-#{token}\b/, css_text_color(token))

    source_files.flat_map do |path|
      File.readlines(path).each_with_index.filter_map do |line, i|
        next unless line.match?(pattern)
        "#{Pathname(path).relative_path_from(Rails.root)}:#{i + 1}"
      end
    end
  end

  RETIRED_GRAYS.each do |retired, replacement|
    it "text-gray-#{retired} 를 쓰지 않는다 (text-gray-#{replacement} 로 바꾼다)" do
      found = offenses(retired)

      expect(found).to be_empty,
        "text-gray-#{retired} 가 #{found.size}곳에 남아 있습니다. " \
        "text-gray-#{replacement} 로 바꿔주세요.\n  " + found.first(20).join("\n  ")
    end
  end

  # 한 방향으로만 본다. match_array 로 쓰면 어떤 단계의 마지막 사용처가
  # 정당하게 사라졌을 때도 빨개진다 — 그건 위반이 아니다
  it "허용하지 않은 회색 단계가 없다" do
    allowed = %w[500 700 900]
    used = source_files
             .flat_map { |p|
               body = File.read(p)
               body.scan(/\btext-gray-(\d{2,3})\b/) +
                 body.scan(/(?<![-\w])color:\s*var\(--color-gray-(\d{2,3})\)/)
             }
             .flatten.uniq.sort

    expect(used - allowed).to be_empty,
      "허용하지 않은 회색: #{(used - allowed).join(', ')}. 쓸 수 있는 것은 #{allowed.join(' · ')} 뿐입니다."
  end
end
