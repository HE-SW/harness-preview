# Step 0: container-node

## 읽어야 할 파일

- `CLAUDE.md`
- `docs/UI-GUIDE.md`
- `src/types/board.ts`
- `src/lib/store.ts` (`setNodeLabel`, `updateNode`)
- `src/components/InlineEdit.tsx`
- `src/components/nodes/ItemNode.tsx` (참조 구조)
- `src/lib/rfAdapt.ts` (phase 4 step 1 — container 변환 추가 필요)
- `@xyflow/react` 문서: `NodeResizer`, `parentId`, `extent`

## 배경

phase 4가 ItemNode를 만들었다. 이 step은 컨테이너(그룹) 노드 컴포넌트와 RF 어댑터에 container 분기를 추가한다. **드롭 hit-test는 step 1, 삭제 cascade는 step 2**.

## 작업

### 1) `src/components/nodes/ContainerNode.tsx`

```tsx
'use client';
import { Handle, Position, NodeProps, NodeResizer } from '@xyflow/react';

export function ContainerNode(props: NodeProps): JSX.Element;
```

Box:
- 사이즈는 `data.size` 또는 RF `width`/`height` (resizer가 갱신)
- `rounded-lg border-2 border-dashed border-neutral-700/70 bg-white/[0.02]`
- 헤더 strip (드래그 핸들) `absolute top-0 left-0 right-0 h-7 px-2 flex items-center bg-neutral-900/40 rounded-t-lg cursor-grab`
  - 안에 라벨: `<InlineEdit>` (헤더에서만 dblclick 편집 — body는 자식 영역)
  - InlineEdit wrapper 에 `nodrag` 클래스
- selected ring `ring-2 ring-violet-400/60`
- drop-target 강조용 클래스 자리 (실제 toggling은 step 1에서):
  - `data.dropTarget === 'accept'` → `ring-2 ring-emerald-400/40`
  - `data.dropTarget === 'reject'` → `ring-2 ring-red-400/60`

NodeResizer:
- `<NodeResizer minWidth={120} minHeight={80} isVisible={selected} handleClassName="size-2 bg-violet-400/60 rounded-sm" lineClassName="border-violet-400/30" />`
- 4 코너 + 4 엣지 (RF 기본). resize 시 `useApp.getState().updateNode(id, { size: { w, h } })`. RF의 dimension change는 `applyRfNodeChanges` 가 store로 흘리되 size 반영도 보장.

핸들 4 — ItemNode와 동일 위치/스타일 (그룹도 연결 가능).

### 2) `rfAdapt.ts` 갱신

container 분기:
- `type: 'container'`
- `style: { width: size?.w ?? 240, height: size?.h ?? 160 }`
- `parentId` (있으면)
- `extent: 'parent'` 자식에게는 부여; container 자신은 X
- container 노드는 자식보다 z-index 낮게 (RF의 `zIndex` 또는 `style.zIndex`)

### 3) Canvas에 등록

```ts
import { ContainerNode } from './nodes/ContainerNode';
const nodeTypes = { item: ItemNode, container: ContainerNode };
```

### 4) `palette-catalog.ts` → 'zone' 매핑

`'zone'` paletteKey가 드롭되면 store는 `type: 'container'` 노드를 생성해야 한다. `addNodeFromPalette`(phase 1 step 3)에서 paletteKey === 'zone' 시 `type: 'container'`로 분기. **본 step은 store 액션 변경이 필요하면 수정한다** — phase 1 step 3 시그니처 내에서 internal 분기.

## Acceptance Criteria

```bash
test -f src/components/nodes/ContainerNode.tsx
grep -q "NodeResizer" src/components/nodes/ContainerNode.tsx
grep -q "container: ContainerNode" src/components/Canvas.tsx
grep -q "extent" src/lib/rfAdapt.ts
npm run lint
npm run typecheck
npm run build
```

수동:
- '구역' 카드 드롭 → 240x160 컨테이너 보임. 컨테이너 헤더 dblclick → 라벨 편집.
- 셀렉트하면 NodeResizer 핸들 8개 보임. 드래그하여 리사이즈, min 120x80 유지.
- 다른 아이템 노드를 컨테이너 위에 시각적으로 겹쳐도 아직 reparent 안됨 (step 1에서 처리).

## 검증 절차

1. AC 통과 + 수동 OK.
2. 컨테이너 z-index가 자식보다 낮아 자식 클릭 가능.
3. `phases/5-containers/index.json` step 0 업데이트.

## 금지사항

- 드롭 hit-test 만들지 마라. 이유: step 1.
- 삭제 cascade 만들지 마라. 이유: step 2.
- 컨테이너 색상을 그라디언트로 만들지 마라. 이유: anti-slop.
- 헤더 strip을 컨테이너 외부 wrapper로 빼지 마라. 이유: RF 노드 안에서 InlineEdit 동작 + nodrag wrapper 일원화.
- 자식 노드의 `extent` 를 'parent' 외 값으로 두지 마라. 이유: 자식이 부모 밖으로 새는 시각 버그.
