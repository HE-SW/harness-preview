# Step 1: pure-helpers

## 읽어야 할 파일

- `CLAUDE.md`
- `docs/ARCHITECTURE.md` (의존 방향)
- `src/types/board.ts` (step 0 산출물)
- `src/types/board.schemas.ts`
- `/Users/khaneol/.claude/plans/image-1-snug-wilkinson.md` 의 "아키텍처 핵심 룰" 섹션 (reparent / cascade / re-id 의도)

## 배경

이 step은 store와 io에서 공유되는 **순수 함수 4개**를 만든다. 모두 입력→출력만 있고 외부 부수효과 없음. Vitest로 검증한다. store는 step 3, io는 step 4에서 이 함수들을 호출한다.

## 작업

### 1) `src/lib/reparent.ts`

```ts
import type { Board, BoardNode } from '@/types/board';

/**
 * 노드를 새 부모(또는 root)로 재배치한다.
 * - position을 절대좌표 기준으로 부모 상대좌표로 재계산
 * - 자기 자신 또는 자손을 부모로 지정 시 throw (호출 측이 사전 차단해야 함)
 * 멱등성: 같은 (nodeId, newParentId) 호출은 같은 결과.
 */
export function reparent(board: Board, nodeId: string, newParentId: string | null): Board;

/**
 * id가 nodeId의 자손인지 (자신 포함 X)
 */
export function isDescendant(nodes: BoardNode[], ancestorId: string, candidateId: string): boolean;
```

### 2) `src/lib/cascadeDelete.ts`

```ts
import type { Board } from '@/types/board';

/**
 * 노드 삭제 정책:
 *   policy='cascade'  → 자손 노드 모두 삭제
 *   policy='detach'   → 자식 parentId를 노드의 parentId로 승격(자식 위치는 부모 절대좌표로 변환)
 * 두 경우 모두 source|target===삭제대상인 엣지를 prune.
 */
export function removeNode(
  board: Board,
  nodeId: string,
  policy: 'cascade' | 'detach'
): Board;
```

### 3) `src/lib/reIdSubgraph.ts`

```ts
import type { Board, BoardNode, BoardEdge, ExportEnvelope } from '@/types/board';

/**
 * 노드/엣지 부분그래프의 id를 새로 발급하고 내부 참조(parentId, edge.source/target)를 다시 매핑.
 * 클립보드 paste 및 import 머지 양쪽에서 사용.
 */
export function reIdSubgraph(input: { nodes: BoardNode[]; edges: BoardEdge[] }): {
  nodes: BoardNode[]; edges: BoardEdge[]; idMap: Record<string, string>;
};

/**
 * Board 단위로 새 id 발급. 내부 노드/엣지 id, parentId, edge endpoint 모두 재매핑.
 * board.id 자체도 새로 발급.
 */
export function reIdBoard(board: Board): Board;

/**
 * Envelope 전체 재발급 (board id 충돌 방지).
 */
export function reIdEnvelope(env: ExportEnvelope): ExportEnvelope;
```

id 발급은 `uuid` v4 사용.

### 4) `src/lib/validateImport.ts`

```ts
import type { ExportEnvelope } from '@/types/board';

export type ImportResult =
  | { ok: true; envelope: ExportEnvelope }
  | { ok: false; error: string };

/**
 * 임의의 string(JSON) 또는 unknown(파싱된 객체)을 받아 zod로 검증.
 * - 파싱 실패 / schema 불일치 / schemaVersion 미지원 시 ok:false + 사람이 읽을 수 있는 ko 메시지.
 */
export function validateImport(raw: unknown): ImportResult;
```

### 5) Vitest 테스트 (`src/lib/__tests__/`)

각 파일에 대해 **최소 다음 케이스**:

- `reparent.test.ts`:
  - 부모 변경 시 position이 새 부모 상대로 재계산
  - root → container, container → root, container A → container B
  - isDescendant: 직계/간접/자기자신/타 트리
  - 자기 자손을 부모로 지정 → throw
- `cascadeDelete.test.ts`:
  - cascade: 자손 다 사라짐, 관련 엣지 prune
  - detach: 자식이 grandparent로 승격되며 절대좌표 보존
  - 엣지 단방향/양방향 prune 모두
- `reIdSubgraph.test.ts`:
  - 모든 id가 새로 발급됨, parentId/edge endpoint도 idMap으로 일관 변환
  - reIdBoard: board.id 변경, 내부 일관성
  - reIdEnvelope: 두 보드 간 노드 id 충돌 없음
- `validateImport.test.ts`:
  - 정상 envelope → ok
  - schemaVersion=2 → ok:false
  - 필드 누락(boards 없음) → ok:false
  - 잘못된 edge variant → ok:false
  - 잘못된 JSON 문자열 → ok:false

## Acceptance Criteria

```bash
test -f src/lib/reparent.ts
test -f src/lib/cascadeDelete.ts
test -f src/lib/reIdSubgraph.ts
test -f src/lib/validateImport.ts
test -f src/lib/__tests__/reparent.test.ts
test -f src/lib/__tests__/cascadeDelete.test.ts
test -f src/lib/__tests__/reIdSubgraph.test.ts
test -f src/lib/__tests__/validateImport.test.ts
npm run typecheck
npm run lint
npx vitest run src/lib/__tests__/reparent.test.ts src/lib/__tests__/cascadeDelete.test.ts src/lib/__tests__/reIdSubgraph.test.ts src/lib/__tests__/validateImport.test.ts
```

## 검증 절차

1. 위 AC 통과 (Vitest 모든 케이스 green).
2. 4개 파일 모두 export가 위 시그니처 그대로.
3. `phases/1-types-store-pure/index.json` step 1 업데이트:
   - 성공 → `"status": "completed"` + `"summary": "pure helpers (reparent/cascadeDelete/reIdSubgraph/validateImport) + Vitest"`

## 금지사항

- store나 persistence를 import 하지 마라. 이유: pure 레이어 — 의존 방향 위반.
- React Flow의 `applyNodeChanges` 등 외부 함수 호출하지 마라. 이유: 도메인 순수.
- 부수효과(`Date.now()` 직접 호출, `localStorage` 접근, `console.log`) 넣지 마라. 이유: 테스트 결정성. 시간이 필요하면 호출 측이 주입.
- uuid를 직접 발급하는 한 곳(`reIdSubgraph.ts`)만 두고 다른 파일에서 uuid를 import 하지 마라. 이유: 발급 정책 일원화. 단, store의 액션 헬퍼(`createBoard`, `addNode`)는 step 3에서 별도 헬퍼를 통해 발급하므로 본 step에서는 신경쓰지 말 것.
- 200줄 넘기지 마라(테스트 제외). 이유: scope 비대화 신호.
