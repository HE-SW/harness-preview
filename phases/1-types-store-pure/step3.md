# Step 3: store

## 읽어야 할 파일

- `CLAUDE.md`
- `docs/ARCHITECTURE.md` (의존 방향, History scope)
- `src/types/board.ts`, `src/types/board.schemas.ts`
- `src/lib/reparent.ts`, `src/lib/cascadeDelete.ts`, `src/lib/reIdSubgraph.ts` (step 1)
- `src/lib/persistence.ts`, `src/lib/migrations.ts` (step 2)
- `/Users/khaneol/.claude/plans/image-1-snug-wilkinson.md` "아키텍처 핵심 룰" 섹션

## 배경

이 step은 Zustand 스토어를 만든다. canonical state는 여기에. zundo로 history 관리. React Flow는 controlled 모드로 다음 phase에서 이 store를 구독한다.

## 작업

### `src/lib/store.ts`

```ts
import { create } from 'zustand';
import { temporal } from 'zundo';
import { useShallow } from 'zustand/react/shallow';
import type {
  Board, BoardNode, BoardEdge, PaletteItem, EdgeVariant, HandleId
} from '@/types/board';

export type AppMode = 'edit' | 'lecture';

export type AppState = {
  // canonical
  current: Board | null;       // 작업 중 보드
  presets: Board[];
  userPalette: PaletteItem[];
  // ui state (history 미포함)
  mode: AppMode;
  dirty: boolean;
  hydrated: boolean;
  presetPanelCollapsed: boolean;
  onboardingDismissed: boolean;
  // actions
  hydrate: () => void;          // mount 시 1회. persistence.loadAll() → state 채움.
  newBoard: (name?: string) => void;
  loadPreset: (id: string) => void;
  saveCurrent: () => { mode: 'overwrite' | 'create'; board: Board };
  saveAs: (name: string) => Board;
  renamePreset: (id: string, name: string) => void;
  deletePreset: (id: string) => void;
  setBoardName: (name: string) => void;

  // node ops
  addNodeFromPalette: (
    paletteKey: string,
    position: { x: number; y: number },
    parentId?: string
  ) => string;                  // returns new node id
  updateNode: (id: string, patch: Partial<BoardNode>) => void;
  setParent: (nodeId: string, newParentId: string | null) => void;  // reparent + 좌표 재계산. zundo.pause/resume로 1 step.
  removeNode: (id: string, policy: 'cascade' | 'detach') => void;
  setNodeLabel: (id: string, label: string) => void;
  applyRfNodeChanges: (changes: unknown) => void;  // React Flow `NodeChange[]`을 받아 store에 반영. position 변경/select/dimension만 수용.

  // edge ops
  addEdge: (e: Omit<BoardEdge, 'id' | 'variant'> & { variant?: EdgeVariant }) => string;
  updateEdge: (id: string, patch: Partial<BoardEdge>) => void;
  reverseEdge: (id: string) => void;
  removeEdge: (id: string) => void;
  applyRfEdgeChanges: (changes: unknown) => void;

  // clipboard helpers (실제 clipboard는 phase 10)
  cloneSelection: (nodeIds: string[]) => { nodes: BoardNode[]; edges: BoardEdge[]; idMap: Record<string,string> };

  // user palette
  addUserPaletteItem: (item: PaletteItem) => void;
  removeUserPaletteItem: (key: string) => void;

  // ui setters
  setMode: (m: AppMode) => void;
  setPresetPanelCollapsed: (v: boolean) => void;
  setOnboardingDismissed: (v: boolean) => void;
};

export const useApp = create(
  temporal<AppState>(
    (set, get) => ({ ... }),
    {
      partialize: (s) => ({
        current: s.current,
        userPalette: s.userPalette,
      }),
      // limit, equality 옵션은 합리적 기본
    }
  )
);

// 셀렉터 (의무 사용)
export const selectNodes = (s: AppState) => s.current?.nodes ?? [];
export const selectEdges = (s: AppState) => s.current?.edges ?? [];
export const selectBoardMeta = (s: AppState) => s.current ? { id: s.current.id, name: s.current.name } : null;
export const selectDirty = (s: AppState) => s.dirty;
export const selectMode  = (s: AppState) => s.mode;
export const selectPresets = (s: AppState) => s.presets;
export const selectUserPalette = (s: AppState) => s.userPalette;

// useShallow 헬퍼 export
export { useShallow };
```

### 동작 규칙

- **dirty 플래그**:
  - true 전이: 노드/엣지/보드명 변경 시
  - false 전이: `saveCurrent`/`saveAs`/`loadPreset`/`newBoard` 직후
- **persistence 쓰기 (debounce 300ms, commit-only)**:
  - `current` → `addNode/removeNode/setParent/updateNode/addEdge/removeEdge/setBoardName/applyRfNodeChanges(position drag-end만)/applyRfEdgeChanges` 후 debounce 300ms로 `saveCurrent`
  - `presets` → 즉시 `savePresets` (드물게 일어남)
  - `userPalette` → 즉시 `saveUserPalette`
  - `presetPanelCollapsed`, `onboardingDismissed` → 즉시
  - **debounce 중 zundo replay (undo/redo) 발생 시**: 쓰기 skip (replay 끝에 1회만 commit). 구현은 zundo의 `pastStates`/`futureStates` 길이 변동 감지 또는 transient flag.
- **`applyRfNodeChanges`**:
  - position 변경: 드래그 종료(`type: 'position'` + `dragging: false`) 시에만 store 반영
  - select/dimension: store 반영 X (UI 전용)
- **`setParent`**:
  - `zundo.pause()` → `reparent(board, nodeId, newParent)` → `zundo.resume()` → 1 history entry로 그룹화
  - 자기 자손을 부모로 지정 시 throw 대신 silently 무시 (호출측이 사전 차단)
- **`removeNode`**: `cascadeDelete.removeNode` 위임. 1 history entry.
- **`hydrate`**:
  - `persistence.loadAll()` → state 세팅
  - `recoveredFromCorrupt` true → 외부에서 토스트 띄울 수 있도록 별도 flag 또는 console.warn (UI는 phase 2 헤더에서 처리)
  - 끝에 `hydrated: true`

### 테스트 (간단한 sanity만, 핵심 로직은 step 1에 있음)

`src/lib/__tests__/store.test.ts`:
- 초기 상태 (current=null, dirty=false, hydrated=false)
- `newBoard` → current 채워짐, dirty=false
- `addNodeFromPalette` → nodes 길이 +1, dirty=true, debounce 후 localStorage 반영 (`vi.useFakeTimers`)
- `removeNode(cascade)` → 자손 사라짐
- `setParent` → 1번의 zundo.pastStates 길이 +1 (그룹화 검증)

## Acceptance Criteria

```bash
test -f src/lib/store.ts
test -f src/lib/__tests__/store.test.ts
npm run typecheck
npm run lint
npx vitest run src/lib/__tests__/store.test.ts
```

## 검증 절차

1. AC 통과.
2. selectors export 명세 준수.
3. `phases/1-types-store-pure/index.json` step 3 업데이트.

## 금지사항

- 컴포넌트 코드를 만들지 마라. 이유: phase 2.
- React Flow 의존을 store.ts 내부에서 직접 import 하지 마라. 이유: store는 도메인. RF 타입이 필요하면 `unknown`으로 받고 변환 함수를 별도 모듈에 두는 식. (`applyRfNodeChanges`의 changes 인자는 `unknown` + 내부에서 `Array.isArray` 체크.)
- 셀렉터를 컴포넌트별로 inline 작성하지 마라. 이유: 모든 셀렉터는 store.ts에 export — 일원화.
- 200줄 가이드는 본 파일은 예외 가능하지만 350줄 넘으면 액션을 별도 파일로 분리.
- zundo `partialize`에 nodes/edges/userPalette 외 필드 넣지 마라. 이유: history scope 명세 준수.
