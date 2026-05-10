# Step 2: edge-popover

## 읽어야 할 파일

- `CLAUDE.md`
- `src/types/board.ts` (`EdgeVariant`)
- `src/lib/edge-variants.ts` (`EDGE_VARIANTS`)
- `src/lib/store.ts` (`updateEdge`, `reverseEdge`, `setNodeLabel` 패턴)
- `src/components/InlineEdit.tsx`
- `src/components/edges/*` (step 0)
- `@xyflow/react` 문서: `useStore`, `EdgeLabelRenderer`, `useReactFlow`

## 배경

이 step은 엣지 선택 시 떠오르는 5 아이콘 popover(4 variants + 방향 반전)와 엣지 라벨 인라인 편집을 추가한다.

## 작업

### 1) `src/components/edges/EdgePopover.tsx`

```tsx
'use client';
export type EdgePopoverProps = {
  edgeId: string;
  // RF가 계산해주는 source/target labelX/labelY를 어댑터에서 받아온다.
  position: { x: number; y: number };
};
export function EdgePopover(p: EdgePopoverProps): JSX.Element | null;
```

내부:
- 5 아이콘: `straight` `network` `dotted` `curve-loop` 각각 작은 SVG 아이콘 + 마지막 ↔ 반전
- 클릭 시 `useApp.getState().updateEdge(edgeId, { variant })` 또는 `reverseEdge(edgeId)`
- 호버 시 `EDGE_VARIANTS[*].label` 툴팁 (`title` 속성)
- 스타일: `flex gap-1 p-1 rounded-md bg-[#141414] border border-neutral-800 shadow-lg/0` (no glow)
- 위치는 `EdgeLabelRenderer` 안에 절대 배치 + `transform: translate(-50%, calc(-100% - 8px))` 로 엣지 라벨 위에

### 2) Canvas 통합

`Canvas.tsx`에서 selected edges를 RF store로 구독:

```ts
const selectedEdgeIds = useStore<string[]>((s) =>
  Array.from(s.edges.values?.() ?? s.edges).filter(e => e.selected).map(e => e.id)
);
```

또는 RF의 `onSelectionChange={({ edges }) => setSelectedEdges(edges)}` 사용.

선택된 엣지 1개일 때 popover 렌더 (다중 선택은 popover 숨김).

각 엣지 컴포넌트가 `<EdgeLabelRenderer>` 안에 popover를 포함시키거나, Canvas 레벨에서 별도 overlay로. **권장: 각 엣지 컴포넌트가 selected일 때만 popover 렌더** — 그러면 RF의 좌표 헬퍼를 그대로 활용.

### 3) 엣지 라벨 인라인 편집

각 엣지 컴포넌트의 `<EdgeLabelRenderer>`에 `<InlineEdit>` (dblclick → 편집):

```tsx
<EdgeLabelRenderer>
  <div style={{ transform: `translate(-50%,-50%) translate(${labelX}px,${labelY}px)`, pointerEvents: 'all' }} className="nodrag nopan">
    <InlineEdit value={data?.label ?? ''} onCommit={(v) => useApp.getState().updateEdge(id, { label: v })}
      className="text-xs bg-[#141414]/90 border border-neutral-800 rounded px-1.5 py-0.5 text-neutral-300"
      placeholder="(라벨)" />
  </div>
</EdgeLabelRenderer>
```

빈 라벨일 땐 InlineEdit가 placeholder를 보여주지 않고 "보이지 않는" 상태가 자연스러움 — 본 컴포넌트 내부에서 `value` 빈 문자열 시 `<button className="size-3 opacity-0 hover:opacity-100">＋</button>` 처럼 작은 액션 핸들로. 단순화를 위해 빈 라벨은 작은 점만 표시(`<span className="size-1 bg-neutral-700 rounded-full" />`).

### 4) `EDGE_VARIANTS` 아이콘

`edge-variants.ts`에 각 variant의 path 미리보기용 작은 SVG 코드 또는 이모지:
- straight: `─`
- network: `▶▶▶` 또는 점 흐름 SVG
- dotted: `┄`
- curve-loop: `↻`
- reverse: `↔`

## Acceptance Criteria

```bash
test -f src/components/edges/EdgePopover.tsx
grep -q "reverseEdge" src/components/edges/EdgePopover.tsx
grep -qE "EdgeLabelRenderer" src/components/edges/EdgePopover.tsx src/components/edges/*.tsx
npm run lint
npm run typecheck
npm run build
```

수동 (e2e variant toggle):
- 엣지 클릭 → popover 5 아이콘. network 클릭 → variant 변경 → 점 흐름. ↔ 클릭 → source/target 스왑(시각).
- 엣지 dblclick → 라벨 편집창 → 한글 입력 → Enter → 칩 표시.
- 다중 셀렉트 시 popover 숨김.

## 검증 절차

1. AC 통과 + 수동 OK.
2. `phases/6-edges/index.json` step 2 업데이트.

## 금지사항

- popover 라이브러리 도입 마라. 이유: scope 외.
- 엣지 라벨에 마크다운/리치 텍스트 허용 마라. 이유: 단순 string.
- variant 변경 시 zundo가 매번 기록되도록 두라(별도 그룹화 불필요). 이유: variant 토글은 1 step씩 의미 있음.
- popover에 키보드 화살표 네비게이션 추가 마라. 이유: scope 외, MVP 단순.
