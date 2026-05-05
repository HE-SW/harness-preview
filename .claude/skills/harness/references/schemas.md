# JSON Schemas

phases 디렉토리의 JSON 파일 스펙. 이 schema 그대로 만들어라. 주석은 schema가 아니므로 실제 JSON에 넣지 마라.

## phases/index.json (top-level)

여러 phase를 관리하는 인덱스. 이미 있으면 `phases` 배열에 append.

```json
{
  "phases": [
    {
      "dir": "0-mvp",
      "status": "pending"
    },
    {
      "dir": "1-auth",
      "status": "pending"
    }
  ]
}
```

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `phases` | array | ✓ | phase 항목 배열 |
| `phases[].dir` | string | ✓ | phase 디렉토리명 (`0-mvp` 식) |
| `phases[].status` | enum | ✓ | `pending` / `completed` / `error` / `blocked`. 초기값 `pending` |
| `phases[].completed_at` | ISO8601 | 자동 | execute.py가 완료 시 기록 |
| `phases[].failed_at` | ISO8601 | 자동 | execute.py가 실패 시 기록 |
| `phases[].blocked_at` | ISO8601 | 자동 | execute.py가 차단 시 기록 |

**금지**: 타임스탬프 필드(`completed_at`, `failed_at`, `blocked_at`)를 수동으로 넣지 마라. execute.py가 자동 기록한다.

## phases/{task-name}/index.json (task 상세)

```json
{
  "project": "template-harness",
  "phase": "0-mvp",
  "steps": [
    { "step": 0, "name": "project-setup", "status": "pending" },
    { "step": 1, "name": "core-types",    "status": "pending" },
    { "step": 2, "name": "api-layer",     "status": "pending" }
  ]
}
```

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `project` | string | ✓ | 프로젝트명 (CLAUDE.md에서 가져옴) |
| `phase` | string | ✓ | task 이름. 디렉토리명과 일치 |
| `steps` | array | ✓ | step 정의 |
| `steps[].step` | int | ✓ | 0부터 시작하는 순번 |
| `steps[].name` | string | ✓ | kebab-case slug |
| `steps[].status` | enum | ✓ | `pending` / `completed` / `error` / `blocked`. 초기값 `pending` |
| `steps[].summary` | string | runtime | step 완료 시 산출물 한 줄 요약. 다음 step에 컨텍스트로 전달됨 |
| `steps[].error_message` | string | runtime | error 시 구체적 사유 |
| `steps[].blocked_reason` | string | runtime | blocked 시 user 개입 필요 사유 |
| `created_at` | ISO8601 | 자동 | execute.py 최초 실행 시 task 레벨에 기록 |
| `steps[].started_at` | ISO8601 | 자동 | execute.py가 step 시작 시 기록 |
| `steps[].completed_at` | ISO8601 | 자동 | execute.py가 완료 시 기록 |
| `steps[].failed_at` | ISO8601 | 자동 | execute.py가 실패 시 기록 |
| `steps[].blocked_at` | ISO8601 | 자동 | execute.py가 차단 시 기록 |

**금지**:
- 모든 타임스탬프 필드 수동 입력 X (execute.py가 처리)
- `summary`, `error_message`, `blocked_reason` 사전에 채우기 X (runtime에 step이 채움)

## phases/{task-name}/step{N}.md

step 파일 본체. 자세한 템플릿은 `assets/step.md.template` 참조.

필수 섹션 (순서 고정):
1. `# Step {N}: {name}` — h1 제목
2. `## 읽어야 할 파일` — 사전 컨텍스트 적재용
3. `## 작업` — 인터페이스/시그니처 수준 지시
4. `## Acceptance Criteria` — 실행 가능 커맨드 (코드 블록)
5. `## 검증 절차` — AC 실행 + 체크리스트 + status 업데이트 지시
6. `## 금지사항` — 구체적 negative 지시

## 상태 전이

```
pending ─┬─→ completed   (AC 통과)
         ├─→ error       (3회 시도 후 실패)
         └─→ blocked     (user 개입 필요)
```

| 전이 | 기록되는 필드 | 기록 주체 |
|------|-------------|----------|
| → `completed` | `completed_at`, `summary` | 세션이 `summary` 작성, execute.py가 timestamp |
| → `error` | `failed_at`, `error_message` | 세션이 `error_message` 작성, execute.py가 timestamp |
| → `blocked` | `blocked_at`, `blocked_reason` | 세션이 `blocked_reason` 작성, execute.py가 timestamp |

## 출력 인코딩 규약

- UTF-8, LF 개행
- JSON: 2-space indent, 한국어/유니코드 그대로 (escape 금지)
- markdown: 코드블록 언어 명시 (`bash`, `ts`, `json` 등)
