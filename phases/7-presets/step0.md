# Step 0: preset-panel

## 읽어야 할 파일

- `CLAUDE.md`
- `docs/UI-GUIDE.md`
- `src/types/board.ts`
- `src/lib/store.ts` (`selectPresets`, `loadPreset`, `renamePreset`, `deletePreset`)
- `src/components/InlineEdit.tsx`
- `src/components/Shell.tsx`
- `src/lib/i18n/ko.ts`

## 배경

이 step은 우측 프리셋 패널의 목록 UI를 만든다. 헤더 저장/새칠판 버튼 wiring과 dirty 다이얼로그는 step 1, 패널 collapse는 step 2.

## 작업

### `src/components/PresetPanel.tsx` (`'use client'`)

```tsx
export function PresetPanel(): JSX.Element;
```

레이아웃:
- 풀 높이, `bg-[#0a0a0a] border-l border-neutral-800 flex flex-col`
- 헤더: 작은 타이틀 `프리셋` (`text-sm font-medium px-3 py-2 text-neutral-400`)
- 목록: `flex-1 overflow-y-auto` 안에 `<button>` 리스트
- 빈 상태 (`presets.length === 0`): `text-xs text-neutral-500 px-3 py-4` "저장된 칠판이 없습니다"

각 프리셋 행:
- `<li>` (또는 `<button>` semantic): `group flex items-center justify-between px-3 py-2 hover:bg-white/5 cursor-pointer`
- 좌측: 보드명 (`<InlineEdit value={p.name} onCommit={v => renamePreset(p.id, v)} />`)
  - InlineEdit의 trigger를 'dblclick' 그대로 사용 — 단일 클릭은 행 전체 클릭 = `loadPreset(p.id)`
  - InlineEdit wrapper에 `onClick={(e) => e.stopPropagation()}` 부착하여 row click과 분리
- 우측: hover 시 보이는 펜(`✎`) / 휴지통(`🗑`) 아이콘 버튼 (`opacity-0 group-hover:opacity-100`)
  - 펜 → InlineEdit 강제 시작 (또는 단순히 시각 힌트)
  - 휴지통 → confirm 직접 띄우거나 즉시 `deletePreset` (단순화: 즉시 삭제 + undo는 zundo 대상이 아니므로 1초 토스트 "삭제됨" — 본 step에서는 즉시 삭제만, undo는 미지원)
- currentBoard.id === preset.id 인 항목은 `bg-white/5 ring-1 ring-violet-400/40` 강조

### Shell 통합

`Shell.tsx` 우측 슬롯에 `<PresetPanel />`. `data-slot="preset"` placeholder 제거.

## Acceptance Criteria

```bash
test -f src/components/PresetPanel.tsx
grep -q "PresetPanel" src/components/Shell.tsx
grep -q "loadPreset" src/components/PresetPanel.tsx
grep -q "renamePreset" src/components/PresetPanel.tsx
grep -q "deletePreset" src/components/PresetPanel.tsx
npm run lint
npm run typecheck
npm run build
```

수동:
- 임시로 `useApp.getState().savePresets([{...}, {...}])`로 더미 프리셋 주입 → 목록에 보임. 클릭 → loadPreset. dblclick → 이름 편집. 휴지통 → 삭제.

## 검증 절차

1. AC 통과 + 수동 OK.
2. `phases/7-presets/index.json` step 0 업데이트.

## 금지사항

- 썸네일 렌더링 추가 마라. 이유: scope 외.
- 검색/정렬 추가 마라. 이유: scope 외.
- 삭제 시 confirm dialog 추가 마라(선택사항이나 본 MVP는 단순 삭제 + 토스트). 이유: 단순.
- 프리셋 행 clickable 영역 안에서 InlineEdit 입력이 row click과 충돌하게 두지 마라. 이유: dblclick 후 입력 중 마우스 클릭이 loadPreset을 trigger하면 안됨 — 입력 중에는 stopPropagation.
