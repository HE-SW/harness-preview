---
name: harness
description: Use this skill whenever the user wants to plan a Harness phase/task, design steps, scaffold phase files, or anything mentioning "harness 프레임워크", "phase 추가/만들기", "step 설계", "task 만들기", "워크플로우 시작", or references to phases/index.json. The skill explores docs/, discusses unknowns with the user, designs self-contained step{N}.md files, and writes phases/<task>/index.json + step files following strict design principles (scope minimization, self-containment, signature-level instructions, executable AC). Make sure to use this skill even when the user does not explicitly say "skill" — phase/step planning is the trigger.
---

# Harness Phase Planner

이 프로젝트는 Harness 프레임워크를 사용한다. 사용자가 phase/task를 추가하거나 step을 설계하려 할 때, 아래 워크플로우대로 진행하라.

## 핵심 원칙

각 step은 **독립된 Claude 세션이 자기 완결적으로 실행**한다. 즉 step 파일은 그 자체로 모든 정보가 들어있어야 한다. "이전 대화에서 논의한" 같은 외부 참조는 금지. 이 skill의 임무는 그 자기완결성을 갖춘 파일들을 만드는 것이다.

`scripts/execute.py`(나중에 사용자가 실행)가 step{N}.md 파일을 한 개씩 새 Claude 세션에 던지므로, 너는 그 세션이 무슨 일을 해야 하는지 step 파일만 보고 100% 이해할 수 있도록 적어야 한다.

## 워크플로우

### A. 탐색

`docs/` 하위(PRD, ARCHITECTURE, ADR, UI-GUIDE 등)와 CLAUDE.md를 모두 읽어 프로젝트 의도·아키텍처·기술 스택을 파악하라. 여러 문서가 있으면 Explore 에이전트를 병렬로 사용해 탐색하라.

탐색 결과는 user에게 요약해서 보여주지 않아도 된다 — 다만 step 작성에 사용할 사실(디렉토리 구조, 기술 스택, 핵심 도메인 용어)은 머릿속에 정리해 둬라.

### B. 논의

구현 전 결정해야 할 모호한 부분(스코프 경계, 기술 선택, 외부 의존, 데이터 모델 등)이 있으면 user에게 짧게 물어보고 합의하라. 추측으로 진행하지 마라.

문서로 결정 가능한 것은 묻지 마라. 명확히 비어있거나 충돌하는 부분만 묻는다.

### C. Step 설계

User가 구현 계획을 지시하면 여러 step으로 나뉜 초안을 만들어 user에게 **chat 메시지로 보여주고** 피드백을 받아라.

**중요 — 명시적 승인 없이 D로 넘어가지 마라.** User 메시지에 step 목록("step 4개 정도로: A, B, C, D")이 들어 있어도 그것은 *user가 머릿속에 그린 draft suggestion*이지 final approved spec이 아니다. 너는 그 list를 받아 다시 정리한 step 분해 초안을 user에게 보여주고, user가 다음과 같은 **명시적 승인 토큰** 중 하나를 보낸 다음에만 D로 넘어가라:

- "OK 진행", "그대로 진행", "승인", "approve", "그래 만들어", "파일 만들어줘", "go ahead" 등

User가 "lgtm", "좋아", "잘 짠 것 같아" 정도만 말하면 confirmation으로 충분. 다만 user가 추가 질문/수정 의견을 주면 다시 C로 돌아가서 수정 초안 보여주고 재승인 받는다.

**C 단계에서 절대 phases/* 파일을 만들지 마라.** D로 넘어간 다음에만 파일 생성.

**필수 설계 원칙은 `references/design-principles.md`에 정리되어 있다. step 초안을 잡기 전에 반드시 읽어라.** 핵심 7개:

1. Scope 최소화 — step 하나당 한 레이어/모듈
2. 자기완결성 — 외부 대화 참조 금지
3. 사전 준비 강제 — 읽어야 할 문서·이전 step 산출물 명시
4. 시그니처 수준 지시 — 인터페이스만, 내부는 에이전트 재량
5. AC는 실행 가능한 커맨드 — `npm test` 같은 진짜 명령어
6. 주의사항은 구체적 — "X를 하지 마라. 이유: Y" 형식
7. 네이밍 — kebab-case slug (`api-layer`, `auth-flow`)

초안 형태(markdown으로 user에게 보여준다):
```
Phase: 0-mvp (4 steps)
  step 0: project-setup — pnpm + Next.js + TypeScript 초기화
  step 1: core-types — 도메인 타입과 zod 스키마 정의
  step 2: api-layer — Next.js API routes + service 레이어
  step 3: auth-flow — NextAuth credentials + JWT 발급/검증
```

피드백을 받고 합의된 다음에만 D로 넘어간다.

### D. 파일 생성

User가 승인하면 아래 파일들을 만든다. 자세한 schema와 템플릿은 `references/schemas.md`와 `assets/`를 참조하라.

#### D-1. `phases/index.json` — top-level

이미 존재하면 `phases` 배열에 새 항목 append. 없으면 새로 만든다.

`assets/phases-index.json.template` 참고.

#### D-2. `phases/<task>/index.json` — task 상세

step 목록을 담는다. 모든 status는 초기 `"pending"`. 타임스탬프 필드(`created_at`, `started_at`, `completed_at` 등)는 절대 수동으로 넣지 마라 — execute.py가 자동 기록한다.

**`model` 필드도 함께 채워라.** 이 phase 실행에 사용할 Claude 모델 (`sonnet` / `opus` / `haiku`). 기준은 `references/model-selection.md`. 의심스러우면 `sonnet`. 새 아키텍처 결정·대규모 리팩터링·재시도 비용이 큰 작업이면 `opus`.

`assets/task-index.json.template` 참고.

#### D-3. `phases/<task>/step{N}.md` — step마다 1개

이 파일이 핵심이다. 독립 세션이 이것만 보고 완전히 작업할 수 있어야 한다.

`assets/step.md.template` 참고. 필수 섹션:
- `## 읽어야 할 파일` (절대 경로 + 이전 step 산출물)
- `## 작업` (인터페이스/시그니처 수준 지시)
- `## Acceptance Criteria` (실행 가능 커맨드)
- `## 검증 절차` (AC 실행 → 체크리스트 → status 업데이트)
- `## 금지사항` (구체적 negative 지시)

**금지사항 작성 패턴**:
```
- 추가 파일 만들지 마라. 이유: 이 step은 인터페이스 정의만 다룬다.
- src/legacy/* 수정하지 마라. 이유: deprecated 영역이며 step 5에서 제거 예정.
```

### E. 실행 (skill의 임무 아님)

Skill이 D를 끝내면 user에게 다음 명령을 안내하라:

```bash
python3 scripts/execute.py <task-name>
python3 scripts/execute.py <task-name> --push   # 완료 후 push
```

execute.py 동작 상세는 `references/execute-runtime.md`를 user가 궁금해할 때 읽고 답하라. 평소엔 안 읽어도 된다.

## 출력 규칙

- 모든 파일은 UTF-8, LF 개행
- JSON: 2-space indent, 한국어는 그대로 (no escape)
- step{N}.md: kebab-case 파일명 — `step0.md`, `step1.md` 식 (이름은 `name` 필드에)
- 디렉토리명: `phases/<숫자-slug>` 형태 권장 (`0-mvp`, `1-auth`)

## Anti-patterns

- step 하나에 frontend + backend + DB 마이그레이션 다 넣기 → Scope 최소화 위반, 쪼개라
- "이전에 합의한 대로" 같은 문구 → 자기완결성 위반, 사실을 그대로 step 파일에 적어라
- AC가 "잘 동작해야 한다", "에러 없어야 한다" → 실행 가능한 커맨드로 바꿔라
- 구현 전체를 코드 블록으로 다 적기 → 시그니처 수준만 적고 나머지는 맡겨라
- `created_at`을 직접 채우기 → execute.py가 자동 기록한다, 비워둬라
- **User 메시지에 step list가 적혀 있다는 이유만으로 D 단계로 직행하기** → list는 draft suggestion일 뿐. 명시적 승인 토큰 없으면 C에서 멈춰서 step 분해 초안 보여주고 confirm 받아라.
- **C 단계에서 phases/* 파일 만들기** → C는 chat 메시지로 보여주는 단계. 파일은 D에서만.

## 진행 점검

phase/step 만든 뒤 user에게 보여줄 마지막 메시지:
1. 만든 파일 경로 목록
2. 다음 명령: `python3 scripts/execute.py <task-name>`
3. error/blocked 발생 시 복구 방법 (references/execute-runtime.md 요약)

## F. 자동 review 호출

D 단계로 phases/* 파일 생성을 끝낸 직후, 같은 턴에 `review` skill을 호출하라. 방금 추가한 phases/* 파일 셋이 변경 대상이 된다.

목적: 작성한 step 분해가 프로젝트의 ARCHITECTURE/ADR/CRITICAL 규칙과 충돌 없는지 마지막 sanity check. 위반 발견 시 user가 execute.py 돌리기 전에 step 파일을 고칠 수 있다.

호출 방법: review skill의 SKILL.md 워크플로우대로 진행. 변경 범위 탐지 단계에서 "방금 만든 phases/<task>/* 파일들"을 명시적 범위로 넘겨라 — git status fallback에 의존하지 마라 (commit 안 했을 수 있음).

Skip 조건: user가 명시적으로 "review 건너뛰어", "그냥 끝내" 같이 말한 경우만. 그 외엔 항상 실행.
