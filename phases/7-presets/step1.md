# Step 1: save-new-flow

## 읽어야 할 파일

- `CLAUDE.md`
- `src/lib/store.ts` (`saveCurrent`, `saveAs`, `newBoard`, `loadPreset`, `selectDirty`)
- `src/components/Header.tsx` (props 인터페이스)
- `src/components/PresetPanel.tsx` (행 클릭 시 loadPreset)
- `src/components/ConfirmDialog.tsx`
- `src/components/Toaster.tsx` (`toast`)
- `src/lib/i18n/ko.ts`

## 배경

이 step은 헤더의 '저장' / '새 칠판' / '다른 이름으로 저장' 버튼과 dirty 상태 보호 다이얼로그를 잇는다.

## 작업

### 1) 저장 정책

`store.saveCurrent()` (phase 1 step 3 시그니처 그대로):
- `current.id`가 `presets`에 있으면 → overwrite, return `{ mode: 'overwrite', board }`
- 없으면 → 사용자에게 이름 prompt 필요 → `saveAs(name)` 호출 책임은 UI에 위임

본 step UI:
- 헤더 '저장' 클릭 →
  - dirty=false라면 noop + 토스트 "저장할 변경 사항 없음"  (옵션: 그냥 always overwrite도 가능. 단순 위해 dirty 무관 항상 시도)
  - 실제로는 단순화: **항상 시도**. 결과 mode가 'overwrite'면 토스트 `ko.toast.updated`, 'create' 분기는 발생 X (saveCurrent는 overwrite only)
  - 만약 `current.id`가 presets에 없으면 → 이름 prompt 모달 → `saveAs(name)` → 토스트 `ko.toast.saved`

### 2) 이름 prompt

`<NamePromptDialog>` (`src/components/NamePromptDialog.tsx`) — `<ConfirmDialog>`의 body에 `<input>` 추가하는 형태가 어색하므로 별도 작은 모달:

```tsx
'use client';
export type NamePromptDialogProps = {
  open: boolean;
  initial?: string;
  onConfirm: (name: string) => void;
  onCancel: () => void;
};
```

- input + Enter commit / Esc cancel + IME 가드 (InlineEdit과 같은 패턴)
- 빈 이름은 `ko.app.untitled` fallback

### 3) Cmd+Shift+S = '다른 이름으로 저장'

본 step에서는 **헤더 버튼만** wiring. 키보드 바인딩은 phase 10. 헤더에 '다른 이름으로 저장' 버튼을 클릭 → 항상 `<NamePromptDialog>` open → `saveAs(name)` (presets에 추가, current.id는 새 발급).

### 4) '새 칠판'

- dirty=true → `<ConfirmDialog>` 3 버튼:
  - 저장하고 시작: `saveCurrent` 또는 (id 미발급이면) NamePrompt → 저장 → `newBoard()`
  - 버리고 시작: `newBoard()`
  - 취소: noop
- dirty=false → 즉시 `newBoard()`

### 5) PresetPanel 행 클릭 시 dirty 가드

`PresetPanel`의 row click이 `loadPreset(id)` 직전에 dirty 체크 → 동일한 3 버튼 다이얼로그.

본 step에서 다이얼로그 호출 로직을 재사용 가능하게 `src/hooks/useDirtyGuard.ts`:

```ts
export function useDirtyGuard(): {
  guardThen: (afterAction: () => void) => void; // dirty면 모달, 아니면 즉시 실행
  dialogElement: JSX.Element | null;            // 컴포넌트가 마운트할 모달 요소
};
```

Header와 PresetPanel에서 이 훅 사용.

### 6) Header props wiring

`Shell.tsx`에서 `<Header onNewBoard={...} onSave={...} onSaveAs={...} />` 채움.

## Acceptance Criteria

```bash
test -f src/components/NamePromptDialog.tsx
test -f src/hooks/useDirtyGuard.ts
grep -q "NamePromptDialog" src/components/Header.tsx src/components/Shell.tsx
grep -q "useDirtyGuard" src/components/Header.tsx src/components/PresetPanel.tsx
npm run lint
npm run typecheck
npm run build
```

수동:
- 새 노드 추가(dirty=true) → 헤더 '저장' → 이름 prompt → 입력 → 토스트 "저장됨" → 우측 패널에 항목 추가.
- 노드 또 추가 → '저장' → 토스트 "업데이트됨".
- '새 칠판' (dirty 없음) → 즉시 빈 보드.
- 노드 추가(dirty=true) → '새 칠판' → 3 버튼 다이얼로그 → '버리고 시작' 선택 → 빈 보드.
- 우측 다른 프리셋 클릭 → dirty 가드 → '저장하고 시작' → 저장 후 그 프리셋 로드.

## 검증 절차

1. AC 통과 + 수동 OK.
2. `phases/7-presets/index.json` step 1 업데이트.

## 금지사항

- 다른 이름으로 저장 시 current.id를 그대로 두지 마라. 이유: presets 충돌. saveAs는 새 id 발급.
- dirty 가드 로직을 컴포넌트별로 복제하지 마라. 이유: useDirtyGuard 단일 출처.
- 키보드 단축키 추가 마라. 이유: phase 10.
- 자동 저장(autosave to presets) 추가 마라. 이유: 명시 저장만 — 자동저장은 `board:current`(작업 중)에 한정.
