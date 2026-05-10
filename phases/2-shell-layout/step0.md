# Step 0: shell

## 읽어야 할 파일

- `CLAUDE.md`
- `docs/ARCHITECTURE.md` (SSR boundary, RF Provider 위치)
- `docs/UI-GUIDE.md` (컬러, 카드 base 스타일, anti-slop)
- `src/types/board.ts`
- `src/lib/store.ts` (`useApp`, `selectMode`)
- `src/lib/persistence.ts` (`subscribeStorageEvent`)
- `src/lib/i18n/ko.ts`
- `src/app/layout.tsx`, `src/app/page.tsx` (현재 placeholder)

## 배경

phase 1이 데이터 레이어를 끝냈다. phase 2는 UI 셸을 만든다. 이 step은 **3컬럼 레이아웃 + ReactFlowProvider + hydration** 만 다룬다. 헤더/팔레트/캔버스/프리셋은 후속 step과 phase에서.

## 작업

### 1) `src/components/Shell.tsx` (`'use client'`)

```tsx
'use client';
import { ReactFlowProvider } from '@xyflow/react';

export function Shell(): JSX.Element;
```

레이아웃:
- 페이지 전체: `bg-[#0a0a0a] text-white min-h-screen flex flex-col`
- 데스크톱 미만(1280px<) 안내 배너: `<= md` 화면에서만 보이는 상단 배너 (Tailwind `lg:hidden`)
- 본문 그리드: 3컬럼 — 좌 240px / 가운데 1fr / 우 320px (`grid grid-cols-[240px_1fr_320px]`)
- 우 패널은 `selectPresetPanelCollapsed` 시 0px (`grid-cols-[240px_1fr_0px]`)
- 각 컬럼은 슬롯만 — 실제 컴포넌트는 phase 3/4/7에서 채움. 본 step에서는 빈 `<aside data-slot="palette" />`, `<main data-slot="canvas" />`, `<aside data-slot="preset" />` placeholder.

### 2) Hydration 처리

```tsx
useEffect(() => {
  useApp.getState().hydrate();
}, []);

const hydrated = useApp(s => s.hydrated);
if (!hydrated) return <SkeletonShell />;
```

`SkeletonShell` 은 같은 3컬럼 다크 박스 (no spinner, no animation).

### 3) Storage 이벤트

`useEffect`에서 `subscribeStorageEvent`로 `board:current` 키 변경 시 토스트 — 본 step에서는 토스트 시스템이 없으므로 `console.warn` placeholder. step 2의 Toaster 도입 후 phase 7에서 wire-up.

### 4) `src/app/page.tsx` 수정

```tsx
import { Shell } from '@/components/Shell';
export default function Page() { return <Shell />; }
```

`page.tsx`는 RSC지만 `Shell`이 `'use client'`이므로 OK. dynamic import 불필요(Shell 자체는 RF 마운트 안 함).

### 5) `<ReactFlowProvider>` 위치

Shell의 가장 바깥에 둠. 자식 컴포넌트(Header/Preset/Canvas)가 `useReactFlow`를 호출 가능하게.

## Acceptance Criteria

```bash
test -f src/components/Shell.tsx
grep -q "'use client'" src/components/Shell.tsx
grep -q "ReactFlowProvider" src/components/Shell.tsx
grep -q "useApp.getState().hydrate" src/components/Shell.tsx
grep -q "Shell" src/app/page.tsx
npm run lint
npm run typecheck
npm run build
```

수동:
- `npm run dev` → `localhost:3000` 에서 3컬럼 빈 레이아웃 + 다크 배경 보임. 콘솔 에러 없음. 새로고침 시 hydration mismatch 없음.

## 검증 절차

1. AC 모두 통과.
2. 데스크톱 안내 배너가 lg 미만에서만 표시되는지 브라우저 리사이즈로 확인.
3. `phases/2-shell-layout/index.json` step 0 업데이트.

## 금지사항

- 헤더 콘텐츠를 만들지 마라. 이유: step 1.
- 팔레트/캔버스/프리셋 콘텐츠를 만들지 마라. 이유: 후속 phase.
- `localStorage`를 컴포넌트 본문/상수에서 직접 참조하지 마라. 이유: SSR. 모든 접근은 store hydrate를 통해.
- React Flow `<ReactFlow />`를 본 step에서 마운트하지 마라. 이유: phase 4. 본 step은 Provider만.
- 애니메이션이나 스피너를 추가하지 마라. 이유: anti-slop. SkeletonShell은 정적 박스.
