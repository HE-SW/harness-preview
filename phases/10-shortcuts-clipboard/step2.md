# Step 2: cheatsheet

## 읽어야 할 파일

- `CLAUDE.md`
- `src/components/ConfirmDialog.tsx`
- `src/components/Header.tsx`
- `src/hooks/useCanvasShortcuts.ts` (step 0/1)
- `src/lib/i18n/ko.ts`

## 배경

이 step은 ? 키 또는 헤더 단축키 버튼으로 열리는 단축키 시트와 헤더 undo/redo 버튼 활성화를 마무리한다.

## 작업

### 1) `src/components/ShortcutsSheet.tsx`

```tsx
'use client';
export function ShortcutsSheet(p: { open: boolean; onClose: () => void }): JSX.Element | null;
```

내용 — 카테고리별 표:

```
편집
  Delete / Backspace   선택 삭제
  Cmd/Ctrl + Z         되돌리기
  Cmd/Ctrl + Shift + Z 다시하기
  Cmd/Ctrl + Y         다시하기
  Cmd/Ctrl + A         전체 선택
  Cmd/Ctrl + C / V / D 복사 / 붙여넣기 / 복제
  Esc                   선택 해제 / 입력 취소

저장
  Cmd/Ctrl + S          저장
  Cmd/Ctrl + Shift + S  다른 이름으로 저장

뷰
  F                     화면 맞춤
  0                     100% 줌
  ]                     우측 패널 토글
```

`<ConfirmDialog>` 또는 자체 modal로 구현. 닫기는 Esc/backdrop/X 버튼. 검색 기능 없음.

### 2) Cmd+S 추가

step 0에서 다루지 않은 Cmd+S → 헤더 onSave 콜백 호출. shortcuts hook에 추가.

### 3) 헤더 undo/redo 활성화

Header.tsx props `onUndo` / `onRedo` 채움:

```ts
<Header
  onUndo={() => useApp.temporal.getState().undo()}
  onRedo={() => useApp.temporal.getState().redo()}
  onShowShortcuts={() => setSheetOpen(true)}
/>
```

`pastStates` / `futureStates` 길이 0이면 버튼 disabled.

### 4) Shell에 ShortcutsSheet 마운트

```tsx
const [sheetOpen, setSheetOpen] = useState(false);
useCanvasShortcuts(); // ?, Cmd+Shift+S 등은 내부에서 콜백 — Shell에서 props 전달 필요
// Shell이 sheet open / NamePrompt open 등 모달 상태 소유.
```

shortcuts hook이 Shell의 setter들을 받을 수 있도록 옵션:

```ts
useCanvasShortcuts({
  onShowShortcuts: () => setSheetOpen(true),
  onSaveAs: () => setNamePromptOpen(true),
  onSave: () => triggerSave(),
});
```

## Acceptance Criteria

```bash
test -f src/components/ShortcutsSheet.tsx
grep -q "ShortcutsSheet" src/components/Shell.tsx
grep -q "useApp.temporal" src/components/Header.tsx
npm run lint
npm run typecheck
npm run build
```

수동:
- ? 또는 헤더 ⌨ 클릭 → 시트 열림. Esc로 닫힘.
- 헤더 undo/redo 버튼 활성/비활성 상태가 history 길이에 따라 갱신.
- Cmd+S → 헤더 onSave 동일 흐름.

## 검증 절차

1. AC 통과 + 수동 OK.
2. `phases/10-shortcuts-clipboard/index.json` step 2 업데이트.

## 금지사항

- 시트에 검색 기능 추가 마라. 이유: 항목이 ~12개로 적음.
- 시트를 별도 라우트로 만들지 마라. 이유: 모달이 적합.
- 단축키 사용자 커스터마이즈 추가 마라. 이유: scope 외.
- pastStates 길이 변화에 따른 헤더 리렌더가 매 mousemove 발생하지 않도록 — 셀렉터로 length만 구독. 이유: 성능.
