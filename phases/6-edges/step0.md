# Step 0: edge-components

## 읽어야 할 파일

- `CLAUDE.md`
- `docs/UI-GUIDE.md`
- `src/types/board.ts` (`EdgeVariant`)
- `src/lib/edge-variants.ts`
- `src/components/Canvas.tsx`
- `@xyflow/react` 문서: `EdgeProps`, `BaseEdge`, `getStraightPath`, `getBezierPath`, `EdgeLabelRenderer`

## 배경

이 step은 4종 엣지 컴포넌트와 그 시각만 만든다. 연결 흐름(onConnect)과 popover는 후속 step.

## 작업

### 4 컴포넌트 (`src/components/edges/`)

각 파일 export:

```tsx
'use client';
import { BaseEdge, EdgeProps, getStraightPath, getBezierPath, getSmoothStepPath, EdgeLabelRenderer } from '@xyflow/react';

export function StraightEdge(p: EdgeProps): JSX.Element;   // getStraightPath, stroke-width 1.5
export function NetworkEdge(p: EdgeProps): JSX.Element;    // getStraightPath, dashed + dashoffset CSS animation
export function DottedEdge(p: EdgeProps): JSX.Element;     // getStraightPath, stroke-dasharray 2 6
export function CurveLoopEdge(p: EdgeProps): JSX.Element;  // 자기 자신 또는 일반 — Bezier control point를 수직으로 띄워 루프 모양
```

공통:
- 색상: `stroke-neutral-400` (selected: `stroke-violet-300`)
- 라벨이 있으면 `<EdgeLabelRenderer>`로 중앙에 작은 칩 (다음 step에서 라벨 편집 추가, 본 step은 표시만)

NetworkEdge CSS (애니):
- `globals.css` 또는 `src/components/edges/network.css`:
  ```css
  @keyframes lukis-dashflow {
    to { stroke-dashoffset: -16; }
  }
  .lukis-network-edge {
    stroke-dasharray: 4 4;
    animation: lukis-dashflow 0.8s linear infinite;
  }
  ```
- NetworkEdge에서 path에 `className="lukis-network-edge"` 부여

CurveLoopEdge:
- source === target 또는 가까운 두 노드일 때 자연스러운 루프가 되도록 Bezier에 큰 control offset (예: `controlX = midX, controlY = midY - 80`)
- 본 step은 시각적 차이가 분명하면 충분.

### Canvas 등록

```ts
import { StraightEdge, NetworkEdge, DottedEdge, CurveLoopEdge } from './edges/...';
const edgeTypes = {
  'straight': StraightEdge,
  'network': NetworkEdge,
  'dotted': DottedEdge,
  'curve-loop': CurveLoopEdge,
};
// <ReactFlow edgeTypes={edgeTypes} ... />
```

`rfAdapt.toRfEdges`에서 `type: edge.variant` 매핑.

## Acceptance Criteria

```bash
test -f src/components/edges/StraightEdge.tsx
test -f src/components/edges/NetworkEdge.tsx
test -f src/components/edges/DottedEdge.tsx
test -f src/components/edges/CurveLoopEdge.tsx
grep -q "edgeTypes" src/components/Canvas.tsx
grep -qE "lukis-dashflow|@keyframes" src/app/globals.css src/components/edges/*.css 2>/dev/null
npm run lint
npm run typecheck
npm run build
```

수동:
- store에 4종 variant의 엣지를 임시 주입 후 캔버스 확인.
- network는 점이 흐름. dotted는 점선 정적. straight 단색 실선. curve-loop는 곡선.
- 라벨 있는 엣지에 칩 표시.

## 검증 절차

1. AC 통과 + 수동 OK.
2. `phases/6-edges/index.json` step 0 업데이트.

## 금지사항

- SMIL `<animate>` 또는 JS rAF 애니 사용 마라. 이유: CSS dashoffset이 GPU 친화 + 단순.
- 4종 외 variant 추가 마라. 이유: 도메인 고정.
- 엣지 색상에 그라디언트 사용 마라. 이유: anti-slop.
- onConnect 핸들러 만들지 마라. 이유: step 1.
- popover 만들지 마라. 이유: step 2.
