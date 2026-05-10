# Step 1: header

## 읽어야 할 파일

- `CLAUDE.md`
- `docs/UI-GUIDE.md` (버튼 base 스타일)
- `src/components/Shell.tsx` (step 0)
- `src/lib/store.ts` (selectors: selectBoardMeta/selectDirty/selectPresetPanelCollapsed)
- `src/lib/i18n/ko.ts`

## 배경

step 0이 3컬럼 셸을 만들었다. 이 step은 상단 헤더 바를 만든다. 모든 버튼은 시각만 — 실제 동작은 후속 phase에서 wire-up. 본 step은 props/이벤트 콜백 인터페이스만 노출하고 callback은 일단 console.log.

## 작업

### 1) `src/components/Header.tsx`

```tsx
'use client';

export type HeaderProps = {
  // 후속 phase 들이 이걸 wire-up 한다. 본 step에서는 모두 console.log placeholder.
  onNewBoard?: () => void;
  onSave?: () => void;
  onSaveAs?: () => void;
  onImport?: () => void;
  onExport?: () => void;
  onUndo?: () => void;
  onRedo?: () => void;
  onShowShortcuts?: () => void;
  onTogglePanel?: () => void;
};

export function Header(props: HeaderProps): JSX.Element;
```

레이아웃:
- 가로 풀폭, 좌측 = 보드명 (`<InlineEdit>` 자리지만 Step 2에서 만드므로 본 step은 `<span>`만), 우측 = 버튼 그룹.
- 버튼 그룹 순서: 되돌리기 / 다시하기 / 새 칠판 / 저장 / 다른 이름으로 저장 / 불러오기 / 내보내기 / ? (단축키) / 패널 토글 / LECTURE (disabled)
- 모든 버튼: `text-neutral-400 hover:text-white text-sm rounded-md px-3 py-1.5 hover:bg-white/5`
- ? 버튼: 동일 스타일, label `?` 또는 `⌨` 이모지
- LECTURE: `opacity-40 cursor-not-allowed pointer-events-none` + tooltip "곧 출시"
- dirty 시 보드명 옆 작은 점 `<span className="size-1.5 bg-violet-400 rounded-full" />` (셀렉션 ring 외 violet 사용 예외 — UI-GUIDE에서 명시)

### 2) Shell에 통합

`Shell.tsx`의 상단 슬롯에 `<Header />` 렌더. props는 모두 미정의 (= 내부 default `console.log`).

### 3) Viewport 안내 배너

step 0의 `<= md` 배너에 `ko.header.viewportWarn` 텍스트 사용.

## Acceptance Criteria

```bash
test -f src/components/Header.tsx
grep -q "HeaderProps" src/components/Header.tsx
grep -q "onSave" src/components/Header.tsx
grep -q "Header" src/components/Shell.tsx
npm run lint
npm run typecheck
npm run build
```

수동:
- `npm run dev` → 헤더 모든 버튼 렌더, hover 상태 보임. LECTURE는 비활성. 모든 버튼 클릭 시 콘솔에 placeholder 로그.

## 검증 절차

1. AC 통과.
2. 다크 테마 + UI-GUIDE 컬러 토큰 사용. neon/glow 없음.
3. `phases/2-shell-layout/index.json` step 1 업데이트.

## 금지사항

- 실제 store 액션을 호출하지 마라. 이유: 후속 phase 들이 props로 wire-up. 헤더는 dumb component.
- 키보드 단축키를 헤더에 바인딩하지 마라. 이유: phase 10.
- 보라/그라디언트/glow 추가 마라. 이유: anti-slop. dirty 점 표시는 violet 단일 예외이며 size-1.5 이하 small dot 한정.
- 새 페이지나 라우트 만들지 마라.
