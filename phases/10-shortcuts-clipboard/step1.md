# Step 1: clipboard

## 읽어야 할 파일

- `CLAUDE.md`
- `src/lib/store.ts` (`cloneSelection`, `addNodeFromPalette` 패턴)
- `src/lib/reIdSubgraph.ts`
- `src/hooks/useCanvasShortcuts.ts` (step 0)
- `@xyflow/react` 문서: 선택 노드 가져오기 (`useReactFlow().getNodes()`)

## 배경

이 step은 Cmd+C/V/D 클립보드 동작을 추가한다. OS 클립보드는 사용하지 않고 **앱 내부 메모리 클립보드**(zustand 슬라이스 또는 모듈 변수)로 단순화 — 페이지 새로고침 시 초기화.

## 작업

### 1) 내부 클립보드 슬라이스

`src/lib/clipboard.ts`:

```ts
import type { BoardNode, BoardEdge } from '@/types/board';

let buffer: { nodes: BoardNode[]; edges: BoardEdge[] } | null = null;

export const clipboard = {
  copy(input: { nodes: BoardNode[]; edges: BoardEdge[] }): void,
  paste(): { nodes: BoardNode[]; edges: BoardEdge[] } | null, // 호출측이 reIdSubgraph 후 store에 추가
  hasContent(): boolean,
};
```

OS 클립보드 사용은 scope 외(navigator.clipboard 권한 등 복잡).

### 2) store에 paste 액션 추가

`store.ts`:

```ts
pasteFromClipboard: (offset?: { x: number; y: number }) => string[]; // 추가된 노드 id들
duplicateSelection: (nodeIds: string[]) => string[];
```

- `pasteFromClipboard`: clipboard.paste → null이면 noop. 결과를 reIdSubgraph → 모든 position에 offset(기본 {x:24, y:24}) → store.current에 append. 셀렉션은 새 노드들로 옮기는 건 RF 책임 — 본 액션은 id만 반환.
- `duplicateSelection`: clipboard 거치지 않고 직접 reIdSubgraph로 복제 + offset.

### 3) useCanvasShortcuts 확장

```ts
case 'c' (Cmd/Ctrl): {
  const selectedNodes = rf.getNodes().filter(n => n.selected).map(n => n.id);
  if (selectedNodes.length === 0) return;
  const sel = useApp.getState().cloneSelection(selectedNodes);
  // cloneSelection은 reIdSubgraph 적용된 결과 — 그대로 clipboard.copy
  clipboard.copy({ nodes: sel.nodes, edges: sel.edges });
  toast('복사됨');
}
case 'v' (Cmd/Ctrl): {
  const ids = useApp.getState().pasteFromClipboard();
  // RF에 새 id로 셀렉션 변경 신호 (옵션) — 단순화: 토스트만
  toast('붙여넣음');
}
case 'd' (Cmd/Ctrl): {
  const selectedNodes = rf.getNodes().filter(n => n.selected).map(n => n.id);
  useApp.getState().duplicateSelection(selectedNodes);
  toast('복제됨');
}
```

### 4) 헤더 Cmd+Shift+S = '다른 이름으로 저장'

step 0에서 보류한 부분. useCanvasShortcuts에서 Cmd+Shift+S 감지 → 헤더 콜백 (Shell에서 받아 NamePromptDialog open).

## Acceptance Criteria

```bash
test -f src/lib/clipboard.ts
grep -q "pasteFromClipboard" src/lib/store.ts
grep -q "duplicateSelection" src/lib/store.ts
grep -q "clipboard.copy" src/hooks/useCanvasShortcuts.ts
npm run lint
npm run typecheck
npm run build
```

수동:
- 노드 2개 선택 → Cmd+C → Cmd+V → 24,24 오프셋 위치에 새 노드 + 엣지(선택 내부였으면) 복제.
- Cmd+D → 즉시 복제.
- 컨테이너 + 자식 함께 복사/붙여넣기 시 parentId가 새 id로 일관 변환.

## 검증 절차

1. AC 통과 + 수동 OK.
2. `phases/10-shortcuts-clipboard/index.json` step 1 업데이트.

## 금지사항

- OS 클립보드(navigator.clipboard) 사용 마라. 이유: 권한/포커스 이슈. 내부 메모리로 충분.
- 컨테이너만 복사 시 자식 자동 포함시키지 마라. 이유: 사용자가 명시적으로 자식까지 선택해야 함 (Cmd+클릭으로 자식 추가). 단순.
- 새로 붙여넣은 노드를 자동으로 셀렉트 처리 마라(시도 가능하나 RF 셀렉션 동기화 복잡). 이유: 단순. 사용자가 직접 선택.
- Vitest로 클립보드 e2e 테스트 작성 마라. 이유: jsdom + RF 통합 비용 큼. 수동으로 충분.
