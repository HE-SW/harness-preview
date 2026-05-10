# Step 1: item-node

## 읽어야 할 파일

- `CLAUDE.md`
- `docs/UI-GUIDE.md`
- `src/types/board.ts` (`HandleId`, `BoardNode`)
- `src/lib/store.ts` (`setNodeLabel`, `selectUserPalette`)
- `src/lib/palette-catalog.ts` (`findPaletteItem`)
- `src/components/InlineEdit.tsx`
- `@xyflow/react` 문서: `Handle`, `Position`, custom node 타입

## 배경

이 step은 캔버스에 표시될 **아이템 노드 컴포넌트**를 만든다. 컨테이너 노드는 phase 5. 4 핸들(l/r/t/b)은 hover/연결 중에만 보이고, 라벨은 dblclick으로 InlineEdit. Canvas에 nodeTypes 등록한다.

## 작업

### 1) `src/components/nodes/ItemNode.tsx`

```tsx
'use client';
import { Handle, Position, NodeProps } from '@xyflow/react';

export function ItemNode(props: NodeProps): JSX.Element;
```

Box 사이즈: `w-24 h-[72px]` (96x72), `rounded-lg bg-[#141414] border border-neutral-800 flex flex-col items-center justify-center gap-1 select-none`.

내부:
- 큰 이모지/이미지 (`text-2xl` 또는 `<img src={iconValue}>` for image kind, 32px)
- 라벨 영역에 `<InlineEdit value={data.label} onCommit={(v) => useApp.getState().setNodeLabel(id, v)} className="text-[11px] text-neutral-300 truncate w-full text-center px-1" inputClassName="text-[11px] bg-neutral-900 outline-none w-full text-center" />`
  - InlineEdit 외곽 wrapper에 `nodrag nopan` 클래스 부여 (RF에 내부 드래그/팬 차단)

selected 상태:
- `selected` prop true 시 `ring-2 ring-violet-400/60`

핸들 4개:
- `<Handle id="l" type="source" position={Position.Left} />` 등 4개. type은 source+target 동시 가능하게 두 번 깔거나 RF connection mode를 'loose'로. 본 step은 source/target 각 4개 = 8개 핸들 — RF 권장 패턴: `connectionMode='loose'` + 핸들 4개로 충분.
- 핸들 visual: `opacity-0` 기본, 노드 hover 또는 RF connect-drag 중 `opacity-100`. 8x8 hit target, 4x4 visible dot (`bg-violet-400/80 rounded-full`).
- 핸들 visibility는 CSS로 — 부모 `group` + `group-hover:opacity-100`. RF의 connect-drag 중에는 `.react-flow__handle.connecting` 같은 selector 활용.

### 2) Canvas에 등록

```ts
// Canvas.tsx
import { ItemNode } from './nodes/ItemNode';
const nodeTypes = { item: ItemNode };
// <ReactFlow nodeTypes={nodeTypes} ... connectionMode="loose" />
```

본 step은 `item` 타입만 등록. `container` 타입은 phase 5.

### 3) store → RF 노드 변환

`useApp` 셀렉터로 가져온 BoardNode[] → RF Node[]로 변환하는 헬퍼:

```ts
// src/lib/rfAdapt.ts
import type { BoardNode, BoardEdge, PaletteItem } from '@/types/board';
import type { Node, Edge } from '@xyflow/react';

export function toRfNodes(boardNodes: BoardNode[], userPalette: PaletteItem[]): Node[];
export function toRfEdges(boardEdges: BoardEdge[]): Edge[];
```

- `data.label`, `data.paletteKey`, `data.iconKind`, `data.iconValue` 노드 data로 전달
- `parentId`, `extent: 'parent'`(있을 때), `position`, `id`, `type`('item' for now)
- container 변환은 phase 5에서 추가

`Canvas.tsx`에서 이 헬퍼로 변환 후 `<ReactFlow nodes={rfNodes} edges={rfEdges} />`.

## Acceptance Criteria

```bash
test -f src/components/nodes/ItemNode.tsx
test -f src/lib/rfAdapt.ts
grep -q "Handle" src/components/nodes/ItemNode.tsx
grep -q "InlineEdit" src/components/nodes/ItemNode.tsx
grep -q "nodeTypes" src/components/Canvas.tsx
npm run lint
npm run typecheck
npm run build
```

수동:
- store에 임시 보드를 hydrate해보고(`useApp.getState().newBoard('테스트')` + dev console에서 직접 노드 push) 캔버스에 96x72 카드 보임. dblclick → 라벨 편집 → Enter commit. hover 시 4 핸들 보임.

## 검증 절차

1. AC 통과.
2. 핸들이 hover 외에는 보이지 않음.
3. `phases/4-canvas-nodes/index.json` step 1 업데이트.

## 금지사항

- 컨테이너 노드 만들지 마라. 이유: phase 5.
- 핸들에 source/target 분리 불필요한 8개 핸들 만들지 마라. 이유: `connectionMode='loose'` + 4개로 충분.
- 노드에 그림자/glow 추가 마라. 이유: anti-slop. selected ring만 사용.
- 노드 안에서 store를 직접 mutate 하는 코드를 라벨 commit 외에 추가 마라. 이유: 단일 액션 경로.
- React Flow `Node.data` 에 함수를 넣지 마라. 이유: serialization 위험. 이벤트는 `useReactFlow` 또는 store 액션으로.
