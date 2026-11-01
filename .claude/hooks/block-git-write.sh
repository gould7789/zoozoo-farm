#!/bin/bash
#
# git의 상태를 바꾸는 조작을 막는다.
#
# dev-flow의 절대 규칙 「커밋·브랜치 생성/이동·머지·푸시는 사용자가 직접
# 실행한다」를 문서가 아니라 구조로 강제한다. 규칙은 전부터 있었지만
# 지켜지지 않았고, 실제로 실수로 커밋한 적이 있다.
#
# PreToolUse에서 exit 2를 반환하면 도구 실행 전에 차단되고,
# stderr가 이유로 Claude에게 전달된다.
#
# 읽기 전용(status / log / diff / show / fetch / merge-tree 등)은 통과시킨다.
# 여기를 넓게 잡으면 조사 자체를 못 하게 된다.

set -uo pipefail

input=$(cat)
command=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')

[[ -z "$command" ]] && exit 0

deny() {
  echo "$1" >&2
  echo "dev-flow 절대 규칙: git 상태 변경은 사용자가 실행한다. 명령어 블록을 출력하고 기다릴 것." >&2
  exit 2
}

# git이 '명령 위치'에 있을 때만 잡는다.
#
# 줄 전체를 부분 일치로 보면 따옴표 안의 문자열까지 걸린다. 실제로
# 이 훅 자신의 주석을 고치려다 차단됐다 — 치환할 문자열에 하위 명령이
# 글자로 들어 있었기 때문이다. 문서에 명령 예시를 쓰는 일이 잦으므로
# 이 오탐은 실제로 작업을 멈춘다.
#
# 앞이 줄 시작이거나 ; & | ( 중 하나일 때만 명령으로 본다.
# eval 로 감싼 우회는 통과하지만, 이 훅의 목적은 고의가 아니라 실수를 막는 것이다.
GIT_HEAD='(^|[;&|(])[[:space:]]*git([[:space:]]+-[^[:space:]]+)*[[:space:]]+'

git_sub() {
  [[ "$command" =~ ${GIT_HEAD}$1([[:space:]]|$) ]]
}

git_sub "commit"      && deny "커밋은 실행하지 않는다."
git_sub "push"        && deny "푸시는 실행하지 않는다."
git_sub "merge"       && deny "머지는 실행하지 않는다."
git_sub "rebase"      && deny "리베이스는 실행하지 않는다."
git_sub "cherry-pick" && deny "cherry-pick은 실행하지 않는다."
git_sub "revert"      && deny "revert는 실행하지 않는다."

# 브랜치 생성만 막는다. 기존 브랜치로 이동하는 것은 통과시킨다
[[ "$command" =~ ${GIT_HEAD}(checkout|switch)([[:space:]]+[^[:space:]]+)*[[:space:]]+-(b|c|B|C)([[:space:]]|$) ]] \
  && deny "브랜치 생성은 실행하지 않는다."
[[ "$command" =~ ${GIT_HEAD}branch[[:space:]]+[^-] ]] \
  && deny "브랜치 생성·삭제는 실행하지 않는다."

# 되돌릴 수 없는 파기
[[ "$command" =~ ${GIT_HEAD}reset[[:space:]]+.*--hard ]] \
  && deny "reset --hard는 되돌릴 수 없다."
[[ "$command" =~ ${GIT_HEAD}clean[[:space:]]+.*-[a-zA-Z]*[dfx] ]] \
  && deny "clean은 추적 외 파일을 지운다. 복구 수단이 없다."

exit 0
