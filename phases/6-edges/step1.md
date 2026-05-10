# Step 1: connect-hook

## 읽어야 할 파일

- `CLAUDE.md`
- `src/types/board.ts` (`HandleId`, `EdgeVariant`)
- `src/lib/store.ts` (`addEdge`)
- `src/lib/rfAdapt.ts`
- `src/components/Canvas.tsx`
- `@xyflow/react` 문서: `Connection`, `OnConnect`, `addEdge` (RF helper)

## 배경

이 step은 노드 핸들 드래그 → 엣지 생성 흐름을 잇는다. 기본 variant는 `straight`. handle id 규약은 `'l'|'r'|'t'|'b'` (phase 4 step 1에서 확정).

## 작업

### 1) `src/hooks/useCanvasConnect.ts`

```ts
import { useCallback } from 'react';
import { Connection, OnConnect } from '@xyflow/react';

export function useCanvasConnect(): OnConnect;
```

동작:
- RF `Connection { source, target, sourceHandle, targetHandle }` 수신
- 셋 중 하나라도 missing → 무시
- self-loop 허용 (source === target)
- handle id 검증: `'l'|'r'|'t'|'b'` 만 (그 외면 무시)
- `useApp.getState().addEdge({ source, sourceHandle, target, targetHandle, variant: 'straight' })`

### 2) Canvas 통합

```ts
const onConnect = useCanvasConnect();
<ReactFlow ... onConnect={onConnect} />
```

`connectionMode="loose"` 는 phase 4 step 1에서 이미 설정.

### 3) 핸들 ID 규약 검증

`ItemNode.tsx` / `ContainerNode.tsx` 의 `<Handle id="...">` 가 `'l'|'r'|'t'|'b'` 정확히 4개씩 — 본 step에서 grep으로 확인하고 어긋난 곳 수정.

### 4) (sanity) Vitest

`src/lib/__tests__/connect.test.ts` (선택):
- store.addEdge에 source/target/handle 모두 들어가면 edge 생성, 누락이면 noop
- variant 미지정 시 'straight' 디폴트

## Acceptance Criteria

```bash
test -f src/hooks/useCanvasConnect.ts
grep -q "onConnect" src/components/Canvas.tsx
grep -qE "id=\"l\"|id=\"r\"|id=\"t\"|id=\"b\"" src/components/nodes/ItemNode.tsx
grep -qE "id=\"l\"|id=\"r\"|id=\"t\"|id=\"b\"" src/components/nodes/ContainerNode.tsx
npm run lint
npm run typecheck
npm run build
```

수동:
- 노드 hover → 핸들 4개 보임.
- 한 노드의 우 핸들 → 다른 노드의 좌 핸들 드래그 → straight 엣지 생성.
- self-loop: 같은 노드의 두 핸들 사이 → curve-loop 아님(기본은 straight) 생성. variant 변경은 step 2에서.

## 검증 절차

1. AC 통과.
2. `phases/6-edges/index.json` step 1 업데이트.

## 금지사항

- variant 결정 로직을 hook 내부에 넣지 마라(기본 straight 외). 이유: 결정 표면 단일화 — 변경은 popover에서.
- React Flow의 `addEdge` helper 사용 마라(이름 충돌). 이유: 우리 store가 canonical, RF state 직접 push 금지.
- 동일 (source, sourceHandle) → (target, targetHandle) 중복 검사 추가 마라. 이유: 사용자가 의도적 중복 가능 (다른 variant). 단순 유지.
- 핸들 hover 비주얼을 hook에서 변경 마라. 이유: 비주얼은 노드 컴포넌트 책임.
