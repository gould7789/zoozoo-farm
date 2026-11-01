---
paths:
  - "app/controllers/sessions_controller.rb"
  - "app/controllers/application_controller.rb"
  - "app/controllers/admin/users_controller.rb"
  - "app/models/user.rb"
---

# 인증 — 왜 이렇게 생겼나

권한 구조와 위협 모델은 `.claude/rules/domain.md` 에 있다. 여기에는 **구현에서 걸린 판단**을 적는다.

Devise 를 쓰지 않는다. 세션·쿠키·bcrypt 를 직접 다루기 위해서다.

## 로그인 제한을 IP 가 아니라 이메일로 거는 이유

현장은 **같은 Wi-Fi(NAT) 아래에서 여러 명이 접속한다.** IP 기준이면 한 사람의 입력 실수로 전원이 막힌다.

```ruby
by: -> { params[:email].to_s.downcase.strip }
```

대소문자와 앞뒤 공백을 정규화하는 이유는, 안 하면 `Admin@…` 과 `admin@…` 이 서로 다른 칸을 써서 **제한을 10번씩 더 받을 수 있기** 때문이다.

## `reset_session` 을 두 번 부른다

| 자리 | 왜 |
| --- | --- |
| 로그인 성공 직후 | 세션 고정 공격 — 공격자가 미리 심어둔 세션 ID 를 그대로 쓰지 못하게 한다 |
| 로그아웃 | 세션 ID 째로 버린다. 값을 하나씩 지우면 빠뜨린다 |

**로그아웃에서는 `reset_session` 을 `redirect_to` 보다 먼저 불러야 한다.** 나중에 부르면 `flash` 가 세션째로 지워져 「로그아웃했습니다」가 안 뜬다.

## 퇴사 처리는 기존 세션에도 즉시 듣는다

`current_user` 가 매 요청 `User.active` 를 다시 조회하기 때문이다. 세션을 따로 무효화하는 장치가 필요 없다 — 실측으로 확인했다(200 → 302).

```ruby
@current_user ||= User.active.find_by(id: session[:user_id])
```

`||=` 는 **요청 안에서만** 듣는다. 요청이 끝나면 인스턴스 변수도 사라진다.

## 자기 자신의 `role` 과 `active` 는 못 바꾼다

```ruby
if @user == current_user
  permitted.delete(:role)
  permitted.delete(:active)
end
```

**마지막 관리자가 권한을 잃으면 복구 수단이 없다.** 회원가입 페이지가 없으므로 화면에서 되돌릴 방법이 없고, `seeds` 는 `find_or_create_by` 라 기존 계정의 역할을 고쳐주지 않는다. 남는 건 DB 직접 수정뿐이다.

삭제도 같다 — 자기 자신은 지울 수 없다.

## 기록을 가진 계정은 지워지지 않는다

`dependent: :restrict_with_error` 라 `destroy` 가 **예외 없이 `false`** 를 돌려준다. 감사 추적(작성자)을 보존해야 하기 때문이다. 화면에서는 삭제 버튼을 감춰 막지만, **직접 요청과 경합에 대한 최종 방어선**으로 컨트롤러 분기를 남긴다.

버튼을 감출 때 사용자마다 기록 수를 세면 N+1 이 된다. **테이블마다 1쿼리(총 5쿼리)로 모아** `Set` 으로 넘긴다.
