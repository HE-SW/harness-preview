# Step 2: dnd-hook

## 읽어야 할 파일

- `CLAUDE.md`
- `docs/ARCHITECTURE.md`
- `src/types/board.ts`
- `src/lib/store.ts` (`addNodeFromPalette`)
- `src/lib/palette-catalog.ts`
- `src/components/Palette.tsx` (drag start payload 형식 — `application/x-lukis-palette`)
- `src/components/Canvas.tsx`
- `@xyflow/react`: `useReactFlow().screenToFlowPosition`

## 배경

이 step은 좌측 팔레트 → 가운데 캔버스 드롭 흐름을 잇는다. 컨테이너 hit-test와 reparent는 phase 5에서 — 본 step에서는 root 레벨로 드롭만 처리한다.

## 작업

### 1) `src/hooks/useCanvasDnD.ts`

```tsx
import { useCallback } from 'react';
import { useReactFlow } from '@xyflow/react';

/**
 * Canvas wrapper에 부착할 dragOver/drop 핸들러를 반환한다.
 * 드롭 좌표는 screenToFlowPosition 으로 변환.
 */
export function useCanvasDnD(): {
  onDragOver: (e: React.DragEvent) => void;
  onDrop: (e: React.DragEvent) => void;
};
```

동작:
- `onDragOver`: `e.preventDefault(); e.dataTransfer.dropEffect = 'copy';` (드롭 허용)
- `onDrop`:
  1. `e.preventDefault()`
  2. `const raw = e.dataTransfer.getData('application/x-lukis-palette')` 비어있으면 무시
  3. `JSON.parse(raw)` 실패 시 무시 (try/catch)
  4. `paletteKey` 추출, 카탈로그 또는 user palette에 존재하지 않으면 무시
  5. `screenToFlowPosition({ x: e.clientX, y: e.clientY })` → flow 좌표
  6. `useApp.getState().addNodeFromPalette(paletteKey, position)` 호출
  7. (phase 5에서 hit-test로 parentId 결정 추가 예정 — 본 step은 root only)

### 2) Canvas.tsx 통합

`<ReactFlow>` 의 wrapping div에 `onDragOver` / `onDrop` 부착:

```tsx
const { onDragOver, onDrop } = useCanvasDnD();
<div className="size-full" onDragOver={onDragOver} onDrop={onDrop}>
  <ReactFlow ... />
</div>
```

### 3) store 액션 보강 (이미 phase 1 step 3에서 시그니처 정의)

`addNodeFromPalette`가 paletteKey 미존재 시 noop으로 처리되는지 확인. 카탈로그 import는 store가 직접 (catalog는 store 하위 의존이므로 OK — phase 1 step 4 참조).

## Acceptance Criteria

```bash
test -f src/hooks/useCanvasDnD.ts
grep -q "screenToFlowPosition" src/hooks/useCanvasDnD.ts
grep -q "application/x-lukis-palette" src/hooks/useCanvasDnD.ts
grep -q "useCanvasDnD" src/components/Canvas.tsx
npm run lint
npm run typecheck
npm run build
```

수동 (e2e 시나리오 1):
- `npm run dev` → 좌측 '구역' 카드를 가운데 캔버스로 드래그하여 놓음 → 96x72 노드(임시로 item 타입으로 표시) 등장. 다른 그룹의 카드 여러 개 드롭.
- 드롭 위치가 마우스 좌표와 정확히 일치 (screenToFlowPosition 검증).

## 검증 절차

1. AC 통과 + 수동 시나리오 OK.
2. `phases/4-canvas-nodes/index.json` step 2 업데이트.

## 금지사항

- 드롭 시 컨테이너 hit-test 만들지 마라. 이유: phase 5.
- 멀티 드래그(여러 카드 동시) 지원 마라. 이유: scope 외.
- DragImage 커스터마이즈 마라. 이유: scope 외, 브라우저 기본 OK.
- Palette → drag image 외 다른 source(파일 드롭 등)을 받지 마라. 이유: 본 step은 팔레트 전용. 외부 파일 import는 phase 8.
- store에 새 액션을 추가하지 마라. 이유: phase 1 step 3에서 정의된 `addNodeFromPalette`를 그대로 사용.
