# Step 2: delete-cascade

## 읽어야 할 파일

- `CLAUDE.md`
- `src/lib/cascadeDelete.ts` (`removeNode` policy)
- `src/lib/store.ts` (`removeNode` action)
- `src/components/ConfirmDialog.tsx`
- `src/lib/i18n/ko.ts`
- `src/components/Canvas.tsx`

## 배경

step 0/1이 컨테이너 노드와 reparent를 만들었다. 이 step은 컨테이너 삭제 시 prompt(자식 cascade vs detach)을 처리한다. 일반 노드 삭제는 별도 prompt 없이 단순 cascade. 단축키 바인딩은 phase 10이지만 본 step은 컨텍스트 메뉴/우클릭 대신 **store에 진입하는 단일 경로**의 정책만 확립한다.

## 작업

### 1) `src/components/ContainerDeleteDialog.tsx`

```tsx
'use client';
export type ContainerDeleteDialogProps = {
  open: boolean;
  containerId: string | null;
  onCancel: () => void;
  onConfirm: (policy: 'cascade' | 'detach') => void;
};
export function ContainerDeleteDialog(p: ContainerDeleteDialogProps): JSX.Element | null;
```

내부적으로 `<ConfirmDialog>` 사용:
- title: `ko.dialog.deleteContainer.title`
- 3 버튼: `cascade` (danger), `detach` (primary), `cancel` (ghost)
- backdrop / Esc → cancel

### 2) Canvas에서 use-case 통합

`Canvas.tsx`에 컨테이너 삭제 의도 입력점은 본 step에서 한 가지만:
- **노드 우클릭 컨텍스트 메뉴 — '삭제'** (간단). 단축키는 phase 10에서 추가.
- 우클릭 메뉴: `Canvas` 내부 작은 컴포넌트 `<NodeContextMenu>` (~40LOC)
  - 항목: '삭제' 한 개.
  - 일반 노드(item) → 즉시 `useApp.getState().removeNode(id, 'cascade')` (자손 없음 케이스에서도 cascade로 통일)
  - 컨테이너 노드 → `ContainerDeleteDialog` open
- 빈 컨테이너에 대해서도 다이얼로그 강제 (consistency). 즉 컨테이너는 항상 prompt.

### 3) 시각 피드백

drag 중 emerald drop-target ring (step 1) + 자기-자손 reject red ring (step 1)은 그대로. 본 step은 추가 시각 변경 없음.

## Acceptance Criteria

```bash
test -f src/components/ContainerDeleteDialog.tsx
grep -q "ContainerDeleteDialog" src/components/Canvas.tsx
grep -q "removeNode" src/components/Canvas.tsx
npm run lint
npm run typecheck
npm run build
```

수동:
- 일반 아이템 노드 우클릭 → 삭제 → 사라짐.
- 컨테이너 노드 우클릭 → 삭제 → 다이얼로그 → 'cascade' → 자손 다 사라짐. undo(`Cmd+Z`는 phase 10에서 와이어업 — 본 step에서는 store API 직접 호출로 검증) 가능.
- 'detach' 선택 → 자식이 grandparent로 승격, 절대 좌표 보존.

## 검증 절차

1. AC 통과 + 수동 OK.
2. `phases/5-containers/index.json` step 2 업데이트.

## 금지사항

- 키보드 단축키 추가 마라. 이유: phase 10.
- 컨테이너 삭제 시 자동으로 cascade 또는 detach 결정하지 마라. 이유: 실수 방지 — 항상 prompt.
- 우클릭 메뉴를 라이브러리(radix) 기반으로 만들지 마라. 이유: scope 외, 자체 ~40LOC.
- store `removeNode` 외 경로로 노드 제거 마라(예: state 직접 splice). 이유: cascade/엣지 prune 일관성.
