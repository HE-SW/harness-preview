# Step 0: canvas-shell

## 읽어야 할 파일

- `CLAUDE.md`
- `docs/ARCHITECTURE.md` (RF Provider 위치, controlled 패턴)
- `docs/UI-GUIDE.md`
- `src/types/board.ts`
- `src/lib/store.ts` (selectors, actions: `applyRfNodeChanges`, `applyRfEdgeChanges`)
- `src/components/Shell.tsx`
- `@xyflow/react` 문서: Controls, snapToGrid, fitView, controlled props

## 배경

phase 1~3이 데이터/셸/팔레트를 만들었다. 이 step은 React Flow를 dynamic import로 마운트하는 캔버스 셸 + Controls + 뷰포트 설정 + Error Boundary만 다룬다. 노드 타입과 드롭 처리는 후속 step.

## 작업

### 1) `src/components/CanvasErrorBoundary.tsx`

```tsx
'use client';
type Props = { children: React.ReactNode };
type State = { error?: Error };
export class CanvasErrorBoundary extends React.Component<Props, State> {
  // componentDidCatch → store.getState().current 를 'board:crash:<ts>'로 백업, toast('crash', 'error')
  // fallback UI: 가운데 카드 + "복구" 버튼 (현재 보드를 newBoard()로 리셋, 백업 키는 보존)
}
```

### 2) `src/components/Canvas.tsx` (lazy mount용)

```tsx
'use client';
import { ReactFlow, Background, Controls } from '@xyflow/react';
import '@xyflow/react/dist/style.css';

export function Canvas(): JSX.Element;
```

설정:
- nodes/edges는 store에서 `useApp(useShallow((s) => s.current?.nodes ?? []))` 등으로 controlled
- nodeTypes/edgeTypes는 본 step에서는 빈 객체. 후속 step에서 채움.
- `onNodesChange={(c) => useApp.getState().applyRfNodeChanges(c)}`
- `onEdgesChange={(c) => useApp.getState().applyRfEdgeChanges(c)}`
- `snapToGrid={true} snapGrid={[8,8]}`
- `minZoom={0.3} maxZoom={2} fitView fitViewOptions={{ padding: 0.2 }}`
- `panOnScroll selectionOnDrag` (멀티셀렉트는 step 3에서 본격 설정 — 여기는 기본 설정만)
- `<Background gap={16} size={1} color="#1f1f1f" />`
- `<Controls position="bottom-right" showInteractive={false} />` 스타일은 다크에 맞춰 className override

### 3) `src/components/CanvasMount.tsx`

```tsx
'use client';
import dynamic from 'next/dynamic';
const Canvas = dynamic(() => import('./Canvas').then(m => m.Canvas), {
  ssr: false,
  loading: () => <div className="size-full bg-[#0a0a0a]" />, // skeleton
});
export function CanvasMount() {
  return (
    <CanvasErrorBoundary>
      <Canvas />
    </CanvasErrorBoundary>
  );
}
```

`Shell`의 가운데 슬롯 placeholder를 `<CanvasMount />`로 교체.

### 4) 가운데 영역 빈 안내

`current?.nodes` 빈 배열이고 `hydrated` true 일 때 가운데에 옅은 안내 텍스트 (`ko.canvas.empty`). React Flow 위에 absolute 오버레이 (`pointer-events-none`).

## Acceptance Criteria

```bash
test -f src/components/Canvas.tsx
test -f src/components/CanvasMount.tsx
test -f src/components/CanvasErrorBoundary.tsx
grep -q "ssr: false" src/components/CanvasMount.tsx
grep -q "@xyflow/react/dist/style.css" src/components/Canvas.tsx
grep -q "CanvasMount" src/components/Shell.tsx
npm run lint
npm run typecheck
npm run build
```

수동:
- `npm run dev` → 가운데 다크 그리드 배경 + 우측 하단 컨트롤(zoom in/out/fit) 보임. 줌/팬 동작. 콘솔 에러 없음. 빈 보드일 때 안내 텍스트 보임.

## 검증 절차

1. AC 통과.
2. 새로고침 시 SSR 에러 없음 (RF는 dynamic+ssr:false).
3. `phases/4-canvas-nodes/index.json` step 0 업데이트.

## 금지사항

- nodeTypes/edgeTypes 채우지 마라. 이유: 후속 step.
- 드래그앤드롭 처리 만들지 마라. 이유: step 2.
- 멀티셀렉트 lasso 등 본격 설정 마라. 이유: step 3.
- Background 색상에 그라디언트 사용 마라. 이유: anti-slop. 단색 그리드만.
- React Flow CSS를 `globals.css`에 import 마라. 이유: dynamic 분리 깨짐.
