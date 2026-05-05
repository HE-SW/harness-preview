---
name: review
description: Use this skill whenever the user asks for a project review, change review, compliance check against project rules, or pre-merge/pre-commit verification — phrases like "변경 사항 리뷰", "프로젝트 리뷰", "이 PR 검증", "코드 리뷰", "compliance check", "ARCHITECTURE 위반 확인", "CRITICAL 규칙 위반", "/review". This skill reads the project's governing docs (CLAUDE.md, docs/ARCHITECTURE.md, docs/ADR.md) and validates a set of changed files against a fixed 5-item checklist (architecture / tech stack / tests / CRITICAL rules / build), then emits a structured table and concrete fix suggestions. Trigger this even when the user does not say "skill" — any review-style request that references project rules counts.
---

# Project Compliance Review

User가 변경 사항 리뷰를 요청하면, 본 스킬은 프로젝트 governing docs와 변경 파일을 비교해 5항목 체크리스트로 결과를 낸다. 본 스킬은 의견(스타일/취향) 리뷰가 아니라 **규칙 준수 검증**에 한정된다.

## 출력 (반드시 이 형식)

리뷰 끝에는 정확히 이 표를 낸다:

```
| 항목 | 결과 | 비고 |
|------|------|------|
| 아키텍처 준수 | ✅/❌/⚠️ | {1-2줄 상세} |
| 기술 스택 준수 | ✅/❌/⚠️ | {1-2줄 상세} |
| 테스트 존재 | ✅/❌/⚠️ | {1-2줄 상세} |
| CRITICAL 규칙 | ✅/❌/⚠️ | {1-2줄 상세} |
| 빌드 가능 | ✅/❌/⚠️ | {1-2줄 상세} |
```

기호:
- ✅ 위반 없음
- ❌ 위반 발견
- ⚠️ 검증 불가 (문서가 placeholder, 빌드 도구 없음 등). 항상 사유 명시.

표 다음에 "## 위반 사항 및 수정 방안" 섹션. ❌ 항목별로 *어디*가 *왜* 위반인지, *어떻게* 고치는지 구체적 파일 경로/라인/명령으로 적어라.

## 워크플로우

### 1. Doc 로드

다음 경로를 순서대로 시도해 governing docs를 읽어라. 파일명 오타 흔함 — 발견하는 대로 진행하되, 오타는 마지막에 코멘트로 남겨라.

- 프로젝트 규칙: `CLAUDE.md` (필수)
- 아키텍처: `docs/ARCHITECTURE.md` → `docs/ARCHITECTRUE.md` → `docs/architecture.md` 순으로 fallback
- ADR: `docs/ADR.md` → `docs/adr.md` → `docs/adr/` 디렉토리
- 코딩 가이드: `docs/rules/coding-guidelines.md` (있으면)

3개 모두 없으면 user에게 경로를 묻고 중단 가능. 1-2개만 있으면 있는 것 기반으로 진행하고, 누락 부분은 ⚠️ 처리.

#### Placeholder 감지

Doc 본문에서 `{...}` 패턴이나 "예: " 위주의 템플릿 문구가 본문 50% 이상이면 그 doc은 **template 미작성 상태**다. 해당 doc로 검증하는 항목은 ❌가 아닌 ⚠️로 표시하고 비고에 "doc이 placeholder 상태라 기준이 없음"이라고 적어라. 이걸 안 구분하면 사용자는 잘못된 ❌를 받게 된다.

### 2. 변경 범위 탐지

다음 우선순위로 변경 파일 셋을 결정하라:

1. `git status --porcelain`에 staged 또는 unstaged 변경 → 그것이 리뷰 대상
2. (1)이 비었으면 `git log -1 --name-only --pretty=` → 마지막 커밋의 파일이 대상 (user에게 "마지막 커밋 기준으로 진행"이라 알려라)
3. (2)도 비었거나 git repo 아니면 user에게 "어느 변경을 리뷰할까요? (브랜치 diff, 커밋 SHA, 파일 목록)" 묻고 중단

`PR #N`, `브랜치 X`, 명시적 SHA 등 user가 범위를 직접 지정하면 그 지시를 우선.

### 3. 5항목 검증

각 항목마다 결과(✅/❌/⚠️)와 1-2줄 비고. 근거는 가능하면 파일 경로:라인 형식.

#### 3.1 아키텍처 준수

ARCHITECTURE doc의 **디렉토리 구조 섹션**을 추출해, 변경 파일들이 그 구조 안에서 적절한 위치에 있는지 확인.

- Doc이 `src/components/` 명시 → 변경 파일이 `src/components/` 내에 있거나 무관한 영역(설정·docs·스크립트)인지
- Doc에 없는 새 top-level 디렉토리가 추가됐다 → ❌
- Doc이 placeholder → ⚠️

#### 3.2 기술 스택 준수

ADR 또는 CLAUDE.md "기술 스택" 섹션에서 **결정된 도구/언어/프레임워크**를 추출. 변경에 그 외 새 의존성이 추가됐는지 확인.

- `package.json` diff에 새 dep, ADR/CLAUDE.md에 언급 없음 → ❌
- 다른 파일 형식 도입 (예: TS 프로젝트인데 새 `.js` 파일) → ❌
- ADR placeholder → ⚠️

#### 3.3 테스트 존재

CLAUDE.md "개발 프로세스"에 TDD CRITICAL이 있으면 신규 기능 코드에 대응하는 테스트 파일 존재 확인.

- 신규 source 파일에 짝이 되는 `*.test.*` / `*_test.*` / `tests/` 항목 없음 → ❌
- 변경이 docs/config/스크립트만 → 해당 없음, ✅
- TDD CRITICAL 자체가 placeholder → ⚠️

#### 3.4 CRITICAL 규칙

CLAUDE.md에서 `CRITICAL:` 토큰이 들어간 줄을 모두 추출. 각 규칙을 변경 파일 내용에 대해 검증.

- 규칙이 자연어라 자동 검증 불가한 것은, 본문에서 키워드 매칭(예: "client에서 외부 API 호출 금지" → 변경된 client component에 `fetch(`/`axios` 등)으로 의심 신호만 보고
- 위반 의심 신호 발견 → ❌, 근거 라인 제시
- 규칙 자체가 `CRITICAL: {placeholder}` → ⚠️

TDD CRITICAL은 3.3에서 처리하니 여기선 스킵하고 비고에 "TDD는 테스트 항목으로 평가" 명시.

#### 3.5 빌드 가능

CLAUDE.md "## 명령어" 섹션에서 build/lint/test 명령을 추출. 각 명령에 대해:

1. 사전 조건 확인 — 예: `npm run`은 `package.json` 존재해야 함. `pytest`는 `pyproject.toml`/`setup.py`/`pytest.ini` 또는 `tests/`. 없으면 그 명령은 ⚠️ ("프로젝트가 해당 도구 미사용").
2. 사전 조건 충족 → 실행. 실패면 ❌, stderr 요약 비고에.
3. 명령 섹션이 placeholder → ⚠️.

빌드 명령 실행은 부작용 가능성 있으니, **lint/test/build 같이 read-only류만** 자동 실행. `dev`, `start`, `deploy`, `db:migrate`, `publish` 등은 절대 실행 금지 — user에게 "수동 확인 필요"로 알려라.

### 4. 표 + 수정 방안 출력

표를 먼저 출력하고, 그 아래에 위반 항목별 fix를 적어라. 수정 방안은:

- 어떤 파일의 어디를 어떻게 바꿀지 (Edit 가능한 수준의 구체성)
- 또는 어떤 명령을 실행하면 되는지
- 단순 "지키세요"식 추상적 권고 금지

수정은 **제안만** 하고 자동 적용하지 마라. User가 명시적으로 "고쳐줘" 하기 전엔 read-only 리뷰다.

## 엣지 케이스

- **Working tree clean + 인자 없음**: 가장 흔한 실수. 단계 2의 fallback 따라 마지막 커밋 사용 + 알림. 절대 "변경 없음 ✅"으로 끝내지 마라 — user는 무언가 리뷰를 원했다.
- **Repo가 harness/template/scaffold류**: ARCHITECTURE가 앱 구조(`src/app` 등) 명시인데 실제 repo는 `.claude/`, `scripts/` 등 다른 골격이면, 표는 정직하게 ❌/⚠️로 채우되 수정 방안에 "doc과 repo 정체성 미스매치 — doc 재작성 또는 README에 템플릿 의도 명시" 같은 근본 처방을 제시.
- **모든 doc 부재**: `CLAUDE.md` 자체가 없으면 본 skill로는 검증 불가. 즉시 user에게 알리고 중단.
- **변경 파일이 100개+**: 카테고리별로 묶어 샘플 검증, 표는 그대로 내고 비고에 "샘플 N개 기준" 명시.

## 자기 점검

표를 내기 전에 마지막으로 확인:

1. ✅/❌/⚠️ 사유가 비고에 명확히 적혔는가?
2. ❌ 각각에 대해 수정 방안이 구체적 (파일·라인·명령)인가?
3. Placeholder doc을 ❌로 잘못 처리하진 않았는가?
4. Build 항목에서 위험 명령(dev/deploy 등)을 자동 실행하진 않았는가?
