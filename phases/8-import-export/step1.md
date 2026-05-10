# Step 1: import

## 읽어야 할 파일

- `CLAUDE.md`
- `src/types/board.ts`
- `src/lib/io.ts` (`parseImport`)
- `src/lib/validateImport.ts`
- `src/lib/reIdSubgraph.ts`
- `src/lib/store.ts` (액션들 — store에 import 결과를 반영하는 단일 진입점 필요)
- `src/components/Header.tsx` (`onImport`)
- `src/components/ConfirmDialog.tsx`
- `src/components/Toaster.tsx`

## 배경

이 step은 사용자가 JSON 파일을 선택 → 검증 → 머지/교체 선택 → store 반영 흐름이다.

## 작업

### 1) store에 import 액션 추가

`store.ts` 보강 (phase 1 step 3 시그니처 확장):

```ts
applyImport: (env: ExportEnvelope, mode: 'merge' | 'replace') => void;
```

- replace: `current/presets/userPalette` 모두 envelope 내용으로 교체. `current`는 envelope.boards[0] 또는 null.
- merge: `presets`에 envelope.boards 추가, `userPalette`에 envelope.userPalette 추가(중복 key는 envelope 우선). `current`는 변경 없음.
- 두 경우 모두 dirty=false, persistence 즉시 commit (presets/userPalette).

### 2) `src/lib/importTrigger.ts`

```ts
import { parseImport } from './io';

/**
 * <input type="file"> 파일 선택 → text 읽고 parseImport 호출 → 결과 콜백.
 */
export function pickAndParseImportFile(
  mode: 'merge' | 'replace',
  onResult: (r: import('./validateImport').ImportResult) => void
): void;
```

내부:
- 동적으로 `<input type="file" accept="application/json">` 만들고 click → change 시 file.text() → parseImport(raw, mode)
- mode='merge'면 reIdEnvelope 적용, replace면 그대로.

### 3) UI 흐름

`Shell.tsx`의 `onImport` 콜백:
1. 먼저 mode 선택 다이얼로그 (`<ConfirmDialog>` 3 버튼: '병합', '교체', '취소'):
   - 병합: 현재 작업 보존 + 프리셋/팔레트만 추가.
   - 교체: dirty 가드(useDirtyGuard) 후 모든 상태 교체. **확인 후에만 실행** (이중 확인).
2. 모드 결정 후 `pickAndParseImportFile(mode, (r) => { ... })`
3. 결과 ok=true → `useApp.getState().applyImport(r.envelope, mode)` + 토스트 `ko.toast.importOk`
4. ok=false → 토스트 `ko.toast.importFail` + console.warn(r.error)

## Acceptance Criteria

```bash
test -f src/lib/importTrigger.ts
grep -q "applyImport" src/lib/store.ts
grep -q "pickAndParseImportFile" src/components/Shell.tsx
npm run lint
npm run typecheck
npm run build
npx vitest run src/lib/__tests__/io.test.ts
```

수동:
- 정상 envelope JSON 만든 뒤 import → 병합 → 우측 프리셋에 추가됨.
- 손상 JSON(brackets 깨뜨림) → 토스트 "잘못된 파일입니다".
- schemaVersion=2로 변조 → 거부.
- '교체' 선택 → dirty 가드 → 진행 → 모든 상태가 envelope로 교체. id 충돌 없음.

## 검증 절차

1. AC 통과 + 수동 OK.
2. `phases/8-import-export/index.json` step 1 업데이트.

## 금지사항

- File System Access API의 saveFilePicker 사용 마라(이전 step 동일). 이유: 호환성.
- merge 시 reId 생략 마라. 이유: id 충돌로 store가 깨짐.
- replace 시 dirty 가드 생략 마라. 이유: 사용자 작업 잠재 손실.
- 부분 import(보드 일부만) 구현 마라. 이유: scope 외.
