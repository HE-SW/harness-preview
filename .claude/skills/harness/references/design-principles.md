# Step 설계 원칙

이 7개 원칙은 step 파일이 독립 세션에서 안정적으로 실행되기 위한 것이다. 위반하면 세션이 길을 잃거나, 의도와 다른 코드를 생성하거나, AC를 만족하지 못한다.

## 1. Scope 최소화

**한 step = 한 레이어/모듈.** 여러 모듈을 동시에 수정해야 하면 step을 쪼개라.

이유: 한 step의 변경 범위가 크면 (a) 실패 시 재시도 비용이 크고 (b) 검증/리뷰가 어렵고 (c) 자가 교정 루프(`MAX_RETRIES=3`)가 의미 있게 동작하지 않는다.

**OK**:
- step 0: package.json + tsconfig + 기본 디렉토리
- step 1: 도메인 타입 정의 (src/types/)
- step 2: API routes (src/app/api/)

**NG**:
- step 0: 프로젝트 셋업 + 도메인 타입 + API + frontend 페이지

## 2. 자기완결성 (Self-containment)

각 step 파일은 독립된 Claude 세션에서 실행된다. **"이전 대화에서 논의한 바와 같이"** 같은 외부 참조 금지. 필요한 정보(데이터 모델, API 스펙, 기술 스택 결정 등)는 전부 step 파일 안에 적는다.

이유: execute.py는 매 step마다 새 `claude -p` 프로세스를 띄운다. 이전 대화 컨텍스트는 없다. 누락된 정보는 추측으로 메워지며 의도와 어긋난다.

**OK**: "Step 1에서 정의한 `User` 타입(`src/types/user.ts`)을 import하여 사용하라."
**NG**: "앞서 합의한 사용자 모델을 그대로 활용하라."

## 3. 사전 준비 강제

step 파일 맨 앞에 `## 읽어야 할 파일` 섹션을 두고 다음을 명시:
- 관련 docs 경로 (`docs/ARCHITECTURE.md`, `docs/ADR.md` 등)
- 이전 step에서 생성/수정된 파일 경로
- 의존하는 외부 라이브러리의 핵심 문서가 있다면 그 경로

이유: 세션이 *작업 시작 전*에 컨텍스트를 적재하도록 강제한다. 이게 없으면 코드만 보고 추측하며 짠다.

## 4. 시그니처 수준 지시

함수/클래스의 **인터페이스(시그니처)만** 제시하고 내부 구현은 에이전트 재량에 맡긴다.

단, **설계 의도에서 벗어나면 안 되는 핵심 규칙**은 반드시 명시:
- 멱등성 (idempotency) 보장 여부
- 보안 제약 (인증, 권한, 입력 검증)
- 데이터 무결성 (트랜잭션, 락)
- 외부 호출 정책 (재시도, 타임아웃)

이유: 모델은 시그니처가 명확하면 합리적인 구현을 한다. 구현체를 다 적으면 (a) step 파일이 비대해지고 (b) 모델이 그저 받아쓰기만 한다 (학습/판단 기회 상실).

**OK**:
```ts
// src/services/auth.ts
class AuthService {
  /**
   * 멱등성 보장: 동일 email로 중복 호출 시 기존 user 반환.
   * password는 bcrypt(cost=12)로 해싱한다.
   */
  signUp(email: string, password: string): Promise<User>
  signIn(email: string, password: string): Promise<JwtToken>
}
```

**NG**: 위 메서드 본문을 다 적기.

## 5. AC는 실행 가능한 커맨드

"~가 동작해야 한다", "에러가 없어야 한다" 같은 추상적 서술은 **금지**. 실제 실행 가능한 검증 커맨드를 적는다.

```bash
npm run typecheck
npm run lint
npm test -- src/services/auth.test.ts
curl -s http://localhost:3000/api/health | jq -e '.ok == true'
```

이유: execute.py는 AC를 보고 자가 검증한다. 실행 불가능한 문구는 검증 자체가 안 된다 → false positive로 step이 "completed" 마킹된다.

## 6. 주의사항은 구체적으로

"조심해라", "주의하라" 대신 **"X를 하지 마라. 이유: Y"** 형식.

**OK**:
- "src/legacy/* 를 수정하지 마라. 이유: deprecated 영역이며 step 5에서 제거 예정."
- "DB 스키마 마이그레이션 파일을 만들지 마라. 이유: prisma migrate dev는 step 3에서 다룬다."

**NG**: "기존 코드 깨뜨리지 않도록 주의."

이유: "주의"는 모델에게 행동 변화를 일으키지 않는다. 무엇을 *하지 말지* + *왜* 가 명시되어야 의사결정에 들어간다.

## 7. 네이밍

step name은 **kebab-case slug**, 핵심 모듈/작업을 한두 단어로 표현.

**OK**: `project-setup`, `core-types`, `api-layer`, `auth-flow`, `db-schema`, `ui-shell`
**NG**: `step1`, `setup_things`, `Implement Login Page (with NextAuth)`, `백엔드`

phase(task) 디렉토리명: `<숫자>-<slug>` 패턴 권장 — `0-mvp`, `1-auth`, `2-billing`. 숫자는 우선순위/단계 표현용.

## 위반 시 신호

작성한 step을 다시 읽으면서 다음이 보이면 원칙 위반:

- step 파일이 200줄 넘음 → Scope 최소화 위반 가능성
- "앞서", "이전에", "방금 논의" 단어 등장 → 자기완결성 위반
- "읽어야 할 파일" 섹션 비어있음 → 사전 준비 강제 위반
- 함수 본문이 step에 다 적힘 → 시그니처 수준 위반
- AC에 자연어만 있음 → AC 실행성 위반
- "주의", "조심" 단어 → 주의사항 구체성 위반
