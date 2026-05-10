# Step 0: export

## 읽어야 할 파일

- `CLAUDE.md`
- `src/types/board.ts` (`ExportEnvelope`)
- `src/lib/io.ts` (`buildEnvelope`, `serializeEnvelope`)
- `src/lib/store.ts` (selectors: `current`, `presets`, `userPalette`)
- `src/components/Header.tsx` (`onExport`)
- `src/components/Toaster.tsx`

## 배경

이 step은 헤더 '내보내기' 버튼 → 현재 보드 + 프리셋 + 사용자 팔레트를 JSON 파일로 다운로드하는 흐름이다.

## 작업

### `src/lib/exportTrigger.ts`

```ts
import { buildEnvelope, serializeEnvelope } from './io';
import type { Board, PaletteItem } from '@/types/board';

/**
 * 브라우저 다운로드 트리거. 파일명 규칙: lukis-board-YYYYMMDD-HHmm.json (UTC X, local time).
 * a 태그 + URL.createObjectURL → click → revoke.
 * SSR 안전: window 미존재 시 throw.
 */
export function downloadEnvelope(input: {
  current: Board | null; presets: Board[]; userPalette: PaletteItem[];
}): void;
```

### Header onExport wiring

`Shell.tsx` 또는 wrapper에서:

```ts
<Header onExport={() => {
  try {
    downloadEnvelope({ current, presets, userPalette });
    toast(ko.toast.exportOk ?? '내보냈습니다', 'success');
  } catch (e) { toast('내보내기 실패', 'error'); }
}} />
```

`ko.ts`에 `exportOk` 추가 (i18n 단일 출처 갱신).

## Acceptance Criteria

```bash
test -f src/lib/exportTrigger.ts
grep -q "downloadEnvelope" src/lib/exportTrigger.ts
grep -q "createObjectURL" src/lib/exportTrigger.ts
grep -q "onExport" src/components/Shell.tsx
npm run lint
npm run typecheck
npm run build
```

수동:
- 헤더 '내보내기' → 다운로드 트리거. 파일 열어 JSON 유효성 + `schemaVersion: 1` 확인.

## 검증 절차

1. AC 통과 + 수동 OK.
2. `phases/8-import-export/index.json` step 0 업데이트.

## 금지사항

- 압축(gzip) 추가 마라. 이유: scope 외, 사람이 읽을 수 있는 JSON 우선.
- File System Access API 사용 마라. 이유: 호환성. a 태그 download만.
- 빈 envelope(보드 0개) export 차단 마라. 이유: 사용자 팔레트만 export 시나리오 가능.
