# Step 2: primitives

## 읽어야 할 파일

- `CLAUDE.md`
- `docs/UI-GUIDE.md`
- `src/components/Shell.tsx` (step 0)
- `src/components/Header.tsx` (step 1)
- `src/lib/i18n/ko.ts`

## 배경

후속 phase들이 공유할 작은 UI primitive 3개를 만든다. 라이브러리 도입 X — 모두 자체 구현 ~40~80LOC.

## 작업

### 1) `src/components/Toaster.tsx`

```tsx
'use client';

export type ToastVariant = 'info' | 'success' | 'error';

// 글로벌 store(작은 zustand 슬라이스). 다른 컴포넌트에서 toast({...}) 호출.
export const toast: (msg: string, variant?: ToastVariant) => void;

export function Toaster(): JSX.Element;
```

- 위치: `top-center`, fixed, `top-4`
- 최대 3개 stack, 각 3초 auto-dismiss, fade-in 0.2s
- 색상: info=neutral-700 bg, success=emerald-700, error=red-700. 텍스트는 white.
- 별도 zustand store(`useToastStore`) — 메인 store와 분리.

`Shell`에 `<Toaster />` 마운트.

### 2) `src/components/InlineEdit.tsx`

```tsx
'use client';

export type InlineEditProps = {
  value: string;
  onCommit: (next: string) => void;
  placeholder?: string;        // 빈 값 fallback 표시용 (기본 ko.app.untitled)
  className?: string;
  inputClassName?: string;
  trigger?: 'dblclick' | 'click';  // 기본 'dblclick'
};
export function InlineEdit(props: InlineEditProps): JSX.Element;
```

동작 명세:
- `dblclick` 트리거 → `<input>` 모드. 현재 값 미리채움, focus + select all.
- Enter → commit (빈 문자열은 placeholder 값 그대로 commit X — `value`로 복원).
- Esc → revert (commit 호출 없음).
- IME 처리: `compositionstart` 동안 Enter 무시, `compositionend` 후 다음 Enter부터 commit. (한글 IME 안전)
- focus blur → commit (Esc로 처리한 직후가 아니면).
- React Flow 노드 안에서 사용 시 wrapper에 `nodrag nopan` 클래스 부여 (props로 받지 않고 사용 측이 wrapping — 사용 가이드 주석으로 안내).

### 3) `src/components/ConfirmDialog.tsx`

```tsx
'use client';

export type ConfirmDialogProps = {
  open: boolean;
  title: string;
  body?: string;
  buttons: Array<{ label: string; variant?: 'primary'|'danger'|'ghost'; onClick: () => void }>;
  onClose: () => void; // ESC/backdrop
};
export function ConfirmDialog(props: ConfirmDialogProps): JSX.Element | null;
```

- 모달: 풀화면 dim `bg-black/60` + 가운데 카드 `rounded-lg bg-[#141414] border border-neutral-800 p-6 max-w-md`.
- ESC 또는 backdrop 클릭 → `onClose`.
- 버튼은 horizontal 끝 정렬, primary는 `bg-white text-black`, danger는 `bg-red-600 text-white`, ghost는 `text-neutral-400 hover:text-white`.
- 포커스 트랩 간단(첫 버튼에 mount 시 focus, Tab 순환은 생략 — primitive 단순 유지).

## Acceptance Criteria

```bash
test -f src/components/Toaster.tsx
test -f src/components/InlineEdit.tsx
test -f src/components/ConfirmDialog.tsx
grep -q "Toaster" src/components/Shell.tsx
npm run lint
npm run typecheck
npm run build
```

수동:
- `npm run dev`. 임시로 Header 어딘가에 `toast('테스트', 'success')` 호출하는 dev-only 버튼은 만들지 말고 — 대신 Shell의 `useEffect`에서 한 번 `toast('hydration ok','info')` 호출하여 동작 확인 후 본 디버그 코드는 commit 전 제거.

## 검증 절차

1. AC 통과.
2. IME 동작: 한글 입력 후 Enter 한 번에 commit. 중간 조합 상태에서 Enter는 무시.
3. `phases/2-shell-layout/index.json` step 2 업데이트.

## 금지사항

- 외부 라이브러리(`react-hot-toast`, `radix-ui`, `headlessui`) 도입 마라. 이유: scope 외, 자체 구현 충분.
- `<dialog>` 태그(브라우저 native modal) 사용 마라. 이유: 스타일 일관성.
- 애니메이션은 fade-in 0.2s 외 추가 마라. 이유: anti-slop motion 가이드.
- InlineEdit에 size 옵션이나 variant를 추가하지 마라. 이유: 사용 측이 className로 충분.
- 토스트에 close X 버튼 추가 마라. 이유: 3초 auto-dismiss로 충분.
