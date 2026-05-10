# Step 1: palette-panel

## 읽어야 할 파일

- `CLAUDE.md`
- `docs/UI-GUIDE.md` (카드 base, 다크 토큰)
- `src/types/board.ts`
- `src/lib/palette-catalog.ts` (step 0 갱신본)
- `src/lib/store.ts` (`selectUserPalette`)
- `src/lib/i18n/ko.ts`
- `src/components/Shell.tsx` (좌측 슬롯 위치)

## 배경

step 0이 데이터를 채웠다. 이 step은 좌측 팔레트 UI를 구현한다. 사용자 추가 항목은 store의 `userPalette`에서 가져와 '내 팔레트' 그룹으로 합친다. 추가 다이얼로그(phase 9)는 본 step에서 만들지 않고 자리(`<button>내 요소 추가</button>`)만 둔다.

## 작업

### `src/components/Palette.tsx` (`'use client'`)

```tsx
export type PaletteProps = {
  onRequestAddUserItem?: () => void; // phase 9에서 wire-up
};
export function Palette(props: PaletteProps): JSX.Element;
```

레이아웃:
- 풀 높이, `overflow-y-auto`, `pr-2`
- 그룹 순서: `PALETTE_GROUPS` 그대로, 마지막에 '내 팔레트' (user 카테고리만, 비어있으면 '+ 내 요소 추가' 버튼만)
- 각 그룹 헤더: sticky `top-0`, `text-xs uppercase tracking-wide text-neutral-500 bg-[#0a0a0a]/95 backdrop-blur-0 px-2 py-1.5`
- 그룹 내 카드 그리드: `grid grid-cols-2 gap-2 px-2`
- 카드: `rounded-md bg-[#141414] border border-neutral-800 hover:border-neutral-700 p-2 cursor-grab select-none`
  - 가운데 큰 이모지(`text-2xl`) + 아래 작은 라벨(`text-[11px] text-neutral-300 truncate text-center`)
- 하단 고정 영역에 '+ 내 요소 추가' 버튼 (텍스트 버튼 스타일)

### Drag start

각 카드에 `draggable="true"` + `onDragStart`:

```ts
e.dataTransfer.setData('application/x-lukis-palette', JSON.stringify({ paletteKey: item.key }));
e.dataTransfer.effectAllowed = 'copy';
// 드래그 고스트는 카드 자체로 (브라우저 기본 OK)
```

### Shell 통합

`Shell.tsx` 의 좌측 슬롯에 `<Palette />` 마운트. `data-slot="palette"` placeholder 제거.

### Vitest (DataTransfer payload)

`src/lib/__tests__/palette.test.ts` (선택) — DataTransfer 직접 테스트는 어려우므로 **렌더만 검증**:
- 모든 fixed 항목이 렌더되는지 (querySelectorAll('[data-palette-key]').length === 12)
- 그룹 헤더 5개 렌더 (또는 user palette 비어있으면 '내 팔레트' 헤더는 옵션)
- `@testing-library/react` 사용

## Acceptance Criteria

```bash
test -f src/components/Palette.tsx
grep -q "draggable" src/components/Palette.tsx
grep -q "application/x-lukis-palette" src/components/Palette.tsx
grep -q "Palette" src/components/Shell.tsx
npm run lint
npm run typecheck
npm run build
npx vitest run src/lib/__tests__/palette.test.ts || true
```

수동:
- `npm run dev` → 좌측에 카드 12개 + 그룹 헤더 5개 보임. 카드를 드래그할 수 있음(브라우저 기본 고스트). 가운데/우측은 placeholder 그대로.

## 검증 절차

1. AC 통과.
2. 다크 토큰 준수 (UI-GUIDE 색상). hover만 변하고 glow/shadow 없음.
3. `phases/3-palette-fixed/index.json` step 1 업데이트.

## 금지사항

- 캔버스에 드롭 처리를 만들지 마라. 이유: phase 4.
- 사용자 추가 다이얼로그를 만들지 마라. 이유: phase 9.
- 카탈로그 정의를 컴포넌트 안에 inline 하지 마라. 이유: 단일 출처는 `palette-catalog.ts`.
- 카드 hover 시 size transform/scale 사용 마라. 이유: anti-slop motion.
- 그룹 collapse(접기) 기능 추가 마라. 이유: scope 외, MVP 단순.
