# execute.py runtime 동작

이 skill은 step 파일을 만들 뿐 실행하지 않는다. 실행은 user가 `python3 scripts/execute.py <task-name>`로 한다. 이 문서는 user가 동작/복구를 물을 때 참고용.

## 명령

```bash
python3 scripts/execute.py 0-mvp                     # 순차 실행
python3 scripts/execute.py 0-mvp --push              # 완료 후 origin에 push
python3 scripts/execute.py 0-mvp --model opus        # 모델 오버라이드
```

**모델 해석 우선순위**: `--model` CLI > `phases/<task>/index.json`의 `model` > 기본 `sonnet`. 선택 기준은 `references/model-selection.md`.

## 자동 처리 항목

- **브랜치**: `feat-<phase-name>` 자동 checkout (없으면 생성). 이미 그 브랜치면 skip.
- **가드레일 주입**: 매 step 프롬프트 앞에 CLAUDE.md + docs/*.md 전체를 붙임.
- **컨텍스트 누적**: 완료된 step의 `summary`를 다음 step 프롬프트에 누적 전달.
- **자가 교정**: step 실패 시 최대 `MAX_RETRIES=3`회 재시도. 직전 `error_message`를 프롬프트에 피드백으로 전달.
- **2단계 커밋**:
  - feat: 코드 변경 (`feat({phase}): step {N} — {name}`)
  - chore: 메타데이터/output 파일 (`chore({phase}): step {N} output`)
- **타임스탬프**: `created_at` (task 레벨, 1회), `started_at`, `completed_at`, `failed_at`, `blocked_at` 자동 기록 (KST, ISO8601).

## 상태 전이 동작

세션이 step에서 status를 명시적으로 업데이트하지 않으면 execute.py는 "did not update status" 에러로 간주하고 retry.

- `completed`: 다음 step 진행
- `error`:
  - `attempt < 3`: status를 `pending`으로 되돌리고 `error_message`를 프롬프트 피드백으로 다음 시도
  - `attempt == 3`: phase 중단 + top-level index에 `failed_at` 기록 + `exit 1`
- `blocked`: 즉시 중단 + top-level index에 `blocked_at` 기록 + `exit 2`

## 복구 절차

### error로 멈춤

1. `phases/<task>/index.json`의 해당 step 열기
2. `status`를 `"pending"`으로 변경
3. `error_message` 필드 삭제
4. 원인이 step 파일 자체의 결함이면 step{N}.md 수정
5. `python3 scripts/execute.py <task>` 재실행 → 그 step부터 이어 진행

### blocked로 멈춤

1. `blocked_reason`에 적힌 사유 해결 (예: API 키 발급, .env 추가)
2. `phases/<task>/index.json`의 해당 step:
   - `status`를 `"pending"`으로 변경
   - `blocked_reason` 삭제
3. 재실행

## execute.py가 의존하는 파일

- `phases/<task>/index.json` (필수): step 목록과 status
- `phases/<task>/step{N}.md` (각 step에 필수)
- `phases/index.json` (선택): top-level 인덱스. 있으면 자동 업데이트, 없으면 무시
- `CLAUDE.md`, `docs/*.md`: 매 프롬프트에 가드레일로 주입
- `claude` CLI (`claude -p`): 시스템에 설치돼 있어야 함

## 출력 파일

각 step 실행 후 `phases/<task>/step{N}-output.json` 생성 (Claude 세션의 stdout/stderr/exitCode 저장). 디버깅용.

## 인용시 핵심

user가 "실행 어떻게?" / "에러 났어"라고 물으면 위 절차에서 필요한 부분만 짧게 인용해서 답하라. 전체 문서를 토해내지 마라.
