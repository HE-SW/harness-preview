# Step 0: shortcuts-bind

## 읽어야 할 파일

- `CLAUDE.md`
- `src/lib/store.ts` (액션들)
- `src/components/Canvas.tsx`
- `src/components/Shell.tsx` (panel toggle, useReactFlow)
- `@xyflow/react` 문서: `useReactFlow().fitView()`, `useReactFlow().setViewport()`

## 배경

이 step은 키보드 단축키를 한 곳에서 처리하는 훅을 만든다. 클립보드(Cmd+C/V/D)는 step 1, 단축키 시트는 step 2.

## 작업

### `src/hooks/useCanvasShortcuts.ts`

```ts
'use client';
import { useEffect } from 'react';
import { useReactFlow } from '@xyflow/react';

export function useCanvasShortcuts(): void;
```

동작 (window keydown 리스너):

| 키 | 동작 |
|---|---|
| Delete / Backspace | 선택된 노드/엣지 모두 삭제. 컨테이너는 삭제 시 prompt(phase 5 `ContainerDeleteDialog`) 호출 — 단일 선택일 때만. 다중 선택 + 컨테이너 포함 시 cascade 일괄. |
| Esc | RF 셀렉션 해제 (`useReactFlow().getNodes()` selected→false), 진행 중 connect 취소 (RF가 자체 처리). 추가로 InlineEdit blur는 InlineEdit 자체에서 처리 — 본 훅은 키 정지 X, 자연스러운 부모 도달 허용. |
| Cmd/Ctrl + Z | `useApp.temporal.getState().undo()` |
| Cmd/Ctrl + Shift + Z 또는 Cmd/Ctrl + Y | redo |
| Cmd/Ctrl + A | RF의 모든 노드 선택 (RF API). |
| F | `fitView({ padding: 0.2 })` |
| 0 | `setViewport({ x: 0, y: 0, zoom: 1 })` |
| ? (Shift + /) | 단축키 시트 open (전역 토스트/모달 전환은 step 2). 본 step에서는 콜백 prop으로 노출. |
| ] | `useApp.getState().setPresetPanelCollapsed(!current)` |

가드:
- 입력 포커스 중(`document.activeElement`가 INPUT/TEXTAREA/[contenteditable]) → **모든** 단축키 무시 (Esc 제외 가능, 단순화는 모두 무시).
- IME composition 진행 중 → 무시 (`compositionstart` set flag, `compositionend` clear).
- 메타키 없는 단축키(F/0/?/])도 입력 포커스 중에는 무시.

### Canvas에서 사용

```ts
// Canvas.tsx
useCanvasShortcuts();
```

### 본 step 미포함

- Cmd+C/V/D (클립보드) → step 1
- Cmd+Shift+S (다른 이름으로 저장) → 본 훅에 추가해도 OK이나 NamePromptDialog 트리거가 헤더 콜백을 거쳐야 하므로 step 1에서 함께 처리.

## Acceptance Criteria

```bash
test -f src/hooks/useCanvasShortcuts.ts
grep -q "fitView" src/hooks/useCanvasShortcuts.ts
grep -q "useApp.temporal" src/hooks/useCanvasShortcuts.ts
grep -q "useCanvasShortcuts" src/components/Canvas.tsx
npm run lint
npm run typecheck
npm run build
```

수동:
- 노드 선택 → Delete → 사라짐. Cmd+Z → 복구.
- F → fitView. 0 → 100% 줌 + 원점.
- ? → 단축키 시트 콜백 호출 (콘솔 로그 임시).
- ] → 우측 패널 토글.
- 헤더 보드명 input에 포커스 → Delete 눌러도 노드 안 사라짐(가드 OK).

## 검증 절차

1. AC 통과 + 수동 OK.
2. `phases/10-shortcuts-clipboard/index.json` step 0 업데이트.

## 금지사항

- 글로벌 keydown 리스너를 두 군데 이상 두지 마라. 이유: 단일 출처. useCanvasShortcuts 한 곳.
- `react-hotkeys-hook` 같은 라이브러리 도입 마라. 이유: scope 외.
- 메타키 매핑을 하드코딩하지 마라(Mac=Cmd, Win/Linux=Ctrl). `e.metaKey || e.ctrlKey` 패턴 사용. 이유: 크로스 플랫폼.
- 단축키와 RF 기본 단축키(Backspace 등) 중복으로 두 번 동작 마라. RF의 `deleteKeyCode={null}`은 phase 4 step 3에서 이미 비활성화.
