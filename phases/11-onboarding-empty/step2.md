# Step 2: seed-board

## 읽어야 할 파일

- `CLAUDE.md`
- `src/lib/io.ts` (`parseImport`)
- `src/lib/store.ts` (`applyImport`, `newBoard`)
- `src/components/Onboarding.tsx` (step 1)
- `src/lib/i18n/ko.ts`

## 배경

이 step은 첫 실행 시 사용자가 시드(예시) 보드를 자동 주입할지 선택할 수 있게 한다. 주입 경로는 io의 headless 함수 → store.applyImport 머지.

## 작업

### 1) `src/lib/seedBoard.ts`

```ts
import type { ExportEnvelope } from '@/types/board';

/**
 * 즉시 사용 가능한 시드 envelope.
 * - 보드 1개: '예시 — 에이전트란 무엇인가'
 *   - 컨테이너 '프로그램' 안에 'Think' 노드
 *   - 외부에 'LLM' 노드 (사용자 카테고리 없음, fixed icon: 'sourcecode' 또는 'computer')
 *   - 두 노드 사이 network 엣지 (ref: 첨부 이미지)
 * - userPalette 비어있음.
 * 정적 객체로 모든 id는 'seed-...' 접두 — applyImport(merge)에서 reIdSubgraph로 새 발급.
 */
export const SEED_ENVELOPE: ExportEnvelope;
```

### 2) Onboarding 마지막 단계에 옵션 버튼

`Onboarding.tsx` 마지막 step:
- '시작하기 (빈 칠판)' → `newBoard()` + dismiss
- '예시 보드로 시작' → `applyImport(SEED_ENVELOPE, 'merge')` + 첫 보드를 `current`로 로드 + dismiss

`applyImport(env, 'merge')` 후 첫 보드 로드는 store가 이미 준비된 액션 조합으로 처리. 필요 시 store에 `loadFirstFromEnvelope()` 같은 헬퍼 추가하지 않고 UI에서 `presets[presets.length-1]` id를 받아 `loadPreset` 호출.

## Acceptance Criteria

```bash
test -f src/lib/seedBoard.ts
grep -q "SEED_ENVELOPE" src/lib/seedBoard.ts
grep -q "예시 보드" src/components/Onboarding.tsx
npm run lint
npm run typecheck
npm run build
```

수동:
- 첫 실행 → 마지막 step → '예시 보드로 시작' → 컨테이너 + 두 노드 + network 엣지 보임.
- 새로고침 → 그대로 유지.
- '시작하기 (빈 칠판)' 선택한 사용자에게는 시드 미주입.

## 검증 절차

1. AC 통과 + 수동 OK.
2. `phases/11-onboarding-empty/index.json` step 2 업데이트.

## 금지사항

- 시드 보드를 매 새로고침 자동 주입 마라. 이유: 사용자 작업 덮어씀.
- 시드를 url fetch 마라. 이유: 오프라인 동작 보장. 정적 import만.
- 시드의 paletteKey에 'user:*' 사용 마라. 이유: 사용자 팔레트 의존하면 키 누락 시 깨짐. fixed key만.
