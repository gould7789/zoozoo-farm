require "rails_helper"

# 라벨은 굵기와 자간으로 구분한다. uppercase 는 쓰지 않는다.
# 판단 근거는 .claude/rules/notes/color.md
#
# spec/lint 에 두는 이유는 color_discipline_spec.rb 와 같다 — 화면을 렌더하지
# 않고 소스를 읽어 금지 토큰을 센다. ERB 린터가 이 저장소에 없어 RSpec 으로 쓴다
#
# 빌드 CSS 에 .uppercase 가 남는 것은 정상이다. Tailwind v4 는 spec 의 .rb 와
# .claude/rules 의 .md 까지 소스로 훑으므로, 금지를 적은 이 파일 자신이 그 클래스를
# 생성시킨다(실측: 두 파일에서 단어를 빼면 0건, 되돌리면 1건). 쓰는 요소가 없어
# 무해하지만, 모르고 빌드 산출물을 grep 하면 「안 지워졌다」로 읽힌다
RSpec.describe "라벨 규율" do
  # 클래스 문자열은 뷰뿐 아니라 헬퍼(nav_link_class 등)에서도 만들어진다.
  # 엔트리 CSS 도 본다 — Trix 처럼 Tailwind 로 못 닿는 자리는 거기에 생짜 CSS 를 쓰므로
  # text-transform: uppercase 가 그리로 들어오면 클래스를 안 거치고 되살아난다
  LABEL_SCANNED = %w[app/views app/helpers app/javascript app/assets/tailwind].freeze

  def label_source_files
    Dir.glob(LABEL_SCANNED.map { |d| Rails.root.join(d, "**", "*") }).select { |p| File.file?(p) }
  end

  # hover:uppercase 같은 변형까지 잡으려면 앞의 경계를 느슨하게 둬야 한다
  def uppercase_offenses
    label_source_files.flat_map do |path|
      File.readlines(path).each_with_index.filter_map do |line, i|
        next unless line.match?(/(?<![-\w])uppercase\b/)
        "#{Pathname(path).relative_path_from(Rails.root)}:#{i + 1}"
      end
    end
  end

  # 화면 텍스트는 한국어뿐이라(domain.md) 이 규칙에 예외가 생길 자리가 없다.
  # 한글에는 대소문자가 없어 text-transform: uppercase 가 아무 일도 하지 않는다
  it "uppercase 를 쓰지 않는다 (라벨은 font-semibold 와 tracking-wider 로 구분한다)" do
    found = uppercase_offenses

    expect(found).to be_empty,
      "uppercase 가 #{found.size}곳에 남아 있습니다. " \
      "한글에는 대소문자가 없어 아무 효과가 없습니다 — 지워주세요.\n  " +
      found.first(20).join("\n  ")
  end
end
