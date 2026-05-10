# Step 1: coachmarks

## 읽어야 할 파일

- `CLAUDE.md`
- `src/lib/store.ts` (`onboardingDismissed`, `setOnboardingDismissed`)
- `src/lib/i18n/ko.ts`
- `src/components/Shell.tsx`

## 배경

이 step은 첫 실행 시 3단계 코치마크 오버레이를 만든다. 한 번 dismiss하면 영속.

## 작업

### `src/components/Onboarding.tsx`

```tsx
'use client';
export function Onboarding(): JSX.Element | null;
```

내부:
- `dismissed = useApp(s => s.onboardingDismissed)` — true면 null 반환.
- `hydrated`가 true일 때만 표시.
- 풀스크린 dim `bg-black/50` 위에 가운데 카드(rounded-lg bg-[#141414] border p-6 max-w-md text-center).
- 3 step state. 다음/건너뛰기/시작하기 버튼.
- 각 step의 텍스트는 `ko.onboarding.step1/2/3`.
- 마지막 step '시작하기' 또는 '건너뛰기' → `setOnboardingDismissed(true)` (persistence 즉시 commit).

본 step은 시각적 단순 모달로 충분 (실제 UI 영역을 가리키는 화살표 X — anti-slop motion 가이드 + 복잡도 회피).

### Shell 통합

```tsx
<>
  ...
  <Onboarding />
</>
```

## Acceptance Criteria

```bash
test -f src/components/Onboarding.tsx
grep -q "Onboarding" src/components/Shell.tsx
grep -q "onboardingDismissed" src/components/Onboarding.tsx
npm run lint
npm run typecheck
npm run build
```

수동:
- localStorage 비운 뒤 새로고침 → 3단계 모달. '다음' 두 번 → '시작하기' → 사라짐.
- 새로고침 → 안 나옴.
- localStorage `onboarding:dismissed` 삭제 후 새로고침 → 다시 나옴.

## 검증 절차

1. AC 통과 + 수동 OK.
2. `phases/11-onboarding-empty/index.json` step 1 업데이트.

## 금지사항

- 화살표 / spotlight 효과 추가 마라. 이유: anti-slop motion. 단순 카드.
- 코치마크가 캔버스 입력을 막는 동안 키보드 단축키 trigger 되게 두지 마라. 이유: 가드. open 시 `pointer-events-none` 캔버스 또는 단축키 disabled flag.
- 코치마크 진행 상태를 store에 저장 마라(현재 step number). 이유: dismissed boolean 한 개로 충분.
- 마운트 시 즉시 페이드인 외 애니 추가 마라. 이유: anti-slop.
