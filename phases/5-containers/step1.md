# Step 1: reparent

## 읽어야 할 파일

- `CLAUDE.md`
- `docs/ARCHITECTURE.md`
- `src/types/board.ts`
- `src/lib/store.ts` (`setParent`, `addNodeFromPalette`)
- `src/lib/reparent.ts` (`isDescendant`)
- `src/components/Canvas.tsx`
- `src/components/nodes/ContainerNode.tsx`
- `src/hooks/useCanvasDnD.ts` (phase 4 step 2)

## 배경

이 step은 reparent 흐름을 캔버스에 잇는다. (a) 팔레트 드롭 시 hit-test로 가장 안쪽 컨테이너에 자동 부모 지정, (b) 기존 노드를 컨테이너로 드래그 시 reparent, (c) 부모 밖으로 드래그 시 detach, (d) 자기 자손 위 드롭 거부.

## 작업

### 1) Hit-test 헬퍼 `src/lib/hitTest.ts`

```ts
import type { BoardNode } from '@/types/board';

/**
 * flow-coordinate point에 대해, 그 점을 포함하는 가장 안쪽(가장 깊은 depth) container 노드 id 반환.
 * excludeId(자기 자신/자손)는 후보에서 제외.
 * 컨테이너 사이즈는 board에 저장된 size + position(부모 상대)으로 절대 사각형 산출.
 */
export function findInnermostContainer(
  nodes: BoardNode[],
  point: { x: number; y: number },
  excludeId?: string
): string | null;

export function getAbsoluteRect(
  nodes: BoardNode[],
  nodeId: string
): { x: number; y: number; w: number; h: number };
```

테스트 `src/lib/__tests__/hitTest.test.ts`:
- 단일 컨테이너 안 → 그 id
- 중첩 컨테이너 — 가장 안쪽 반환
- 컨테이너 밖 → null
- excludeId가 자기/자손이면 후보 제외

### 2) `useCanvasDnD` 보강 (phase 4 step 2 갱신)

`onDrop`에서:
1. `point = screenToFlowPosition(...)`
2. `parentId = findInnermostContainer(nodes, point)`  (없으면 root)
3. `addNodeFromPalette(paletteKey, point, parentId ?? undefined)`

store의 `addNodeFromPalette`는 parentId 인자를 받으면 position을 부모 절대좌표 → 부모 상대좌표로 변환해 저장.

### 3) Drop-target 시각 피드백

`Canvas.tsx`에 dragOver 중인 컨테이너를 추적할 로컬 state(컴포넌트 내부, store 미오염):

```ts
const [hoverContainerId, setHoverContainerId] = useState<string | null>(null);
const [hoverReject, setHoverReject] = useState<boolean>(false);
```

- `onDragOver`에서 좌표로 hit-test, `setHoverContainerId(id)`
- `onDragLeave` 또는 `onDrop`에서 둘 다 reset
- 어댑터(`rfAdapt`)는 `data.dropTarget` 필드를 동적으로 부여하지 못함(controlled props는 store 기반)이므로, **Canvas에서 nodes 변환 후 hoverContainerId를 마지막에 inject**:
  ```ts
  const rfNodes = useMemo(() => {
    const base = toRfNodes(boardNodes, userPalette);
    if (!hoverContainerId) return base;
    return base.map(n => n.id === hoverContainerId
      ? { ...n, data: { ...n.data, dropTarget: hoverReject ? 'reject' : 'accept' } }
      : n);
  }, [boardNodes, userPalette, hoverContainerId, hoverReject]);
  ```

### 4) 기존 노드 reparent on drag-end

React Flow는 `onNodeDragStop` 이벤트 제공. 다음을 처리:

```ts
onNodeDragStop={(event, node) => {
  const point = node.positionAbsolute ?? screenToFlowPosition({ x: event.clientX, y: event.clientY });
  const target = findInnermostContainer(nodes, point, node.id);
  if (node.id === target) return; // safety
  // 자기 자손이면 reject — store.setParent에서 isDescendant 체크 후 silently 무시
  // 부모 밖이면 target=null → detach
  useApp.getState().setParent(node.id, target);
}}
```

자기 자손 hit-test 차단:
- `findInnermostContainer(nodes, point, /*exclude*/ node.id)` — exclude의 자손도 후보 제외 (`isDescendant` 사용)
- 따라서 자기 자손 위 드롭 시 hit 결과 = null → detach 또는 nearest 외부 container

### 5) Reject 시각 (자기 자손 위 드래그 중)

`onNodeDrag` 핸들러로 dragging 중 `node.id`와 그 자손이 hover된 container라면 `hoverReject=true` 세팅. 일반 hit는 false.

## Acceptance Criteria

```bash
test -f src/lib/hitTest.ts
test -f src/lib/__tests__/hitTest.test.ts
grep -q "findInnermostContainer" src/components/Canvas.tsx
grep -q "onNodeDragStop" src/components/Canvas.tsx
grep -q "dropTarget" src/lib/rfAdapt.ts
npm run lint
npm run typecheck
npx vitest run src/lib/__tests__/hitTest.test.ts
npm run build
```

수동 (e2e):
- 팔레트의 'Think'(예: 사용자 카드 또는 일반 아이템)를 컨테이너 위로 드롭 → 컨테이너 자식으로 들어감(드래그 중 emerald ring).
- 자식 노드를 컨테이너 밖으로 드래그 → detach. 다시 다른 컨테이너로 드래그 → 재 부모.
- 컨테이너 자체를 자기 자식 위로 드래그 → 빨강 ring + drop 무시.

## 검증 절차

1. AC 통과 + 시나리오 모두 OK.
2. 자식이 부모 밖으로 새지 않음(`extent: parent`).
3. `phases/5-containers/index.json` step 1 업데이트.

## 금지사항

- store에 새 액션 추가 마라 (`setParent` 와 `addNodeFromPalette` 사용). 이유: 액션 표면 최소화.
- hit-test에 R-Tree 같은 자료구조 도입 마라. 이유: 노드 수가 작은 본 앱에는 O(N) 충분.
- drag-over 중 store mutation 발생시키지 마라. 이유: 매 mousemove마다 zundo history 폭발. drop / dragStop 시에만 store에 commit.
- 자기 자손 차단 로직을 컴포넌트에 분산하지 마라. 이유: `isDescendant` 단일 출처(`reparent.ts`).
