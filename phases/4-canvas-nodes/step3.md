# Step 3: multi-select

## 읽어야 할 파일

- `CLAUDE.md`
- `docs/UI-GUIDE.md`
- `src/components/Canvas.tsx` (step 0~2)
- `@xyflow/react` 문서: `selectionOnDrag`, `panOnDrag`, `multiSelectionKeyCode`, `selectionMode`

## 배경

이 step은 React Flow의 멀티셀렉션 설정과 시각 피드백만 다룬다. 셀렉션을 활용하는 동작(삭제/복사/이동)은 phase 10.

## 작업

### Canvas.tsx 설정 추가

- `selectionOnDrag={true}` (빈 캔버스에서 드래그 = 박스 셀렉션)
- `panOnDrag={[1, 2]}` (휠 클릭/우클릭으로만 팬 — 좌클릭 빈 영역 드래그는 셀렉션)
- `multiSelectionKeyCode={['Shift']}`
- `selectionMode="partial"` (박스에 일부만 걸쳐도 선택)
- `selectionKeyCode="Shift"` 또는 RF 기본 (Shift+클릭 누적)
- `deleteKeyCode={null}` (삭제 키는 phase 10 hook에서 처리, RF 기본 비활성화)

### CSS

`globals.css` 또는 Canvas 인접 모듈에 RF 셀렉션 박스 스타일:

```css
.react-flow__selection {
  background: rgb(124 58 237 / 0.08); /* violet-600/8 */
  border: 1px dashed rgb(196 181 253 / 0.6); /* violet-300/60 */
}
.react-flow__node.selected, .react-flow__node:focus { outline: none; }
/* selected ring은 ItemNode 내부에서 처리 (step 1) */
.react-flow__edge.selected .react-flow__edge-path {
  stroke-width: 2.5;
}
```

### 본 step에서 추가하지 않을 것

- 단축키 (Cmd+A 등) → phase 10
- 그룹 이동(부모 따라 자식 이동) → React Flow 기본 동작이 처리
- 셀렉션 액션(삭제/복사) → phase 10

## Acceptance Criteria

```bash
grep -q "selectionOnDrag" src/components/Canvas.tsx
grep -q "multiSelectionKeyCode" src/components/Canvas.tsx
grep -q "panOnDrag" src/components/Canvas.tsx
grep -q "deleteKeyCode" src/components/Canvas.tsx
npm run lint
npm run typecheck
npm run build
```

수동:
- 빈 영역 드래그 → 점선 박스 + 노드 다중 선택. Shift+클릭 추가 선택. 휠/우클릭 드래그로 팬. 좌클릭 빈 영역은 박스 셀렉션 (팬 X).
- Delete 키 눌러도 RF는 노드를 지우지 않음 (phase 10에서 별도 처리 예정).

## 검증 절차

1. AC 통과 + 수동 시나리오 확인.
2. selection 박스 스타일이 다크 테마에 어울리고 anti-slop 가이드 준수 (얇은 violet/8% 톤).
3. `phases/4-canvas-nodes/index.json` step 3 업데이트.

## 금지사항

- 키보드 핸들러 추가 마라. 이유: phase 10.
- 셀렉션 액션 컨텍스트 메뉴 추가 마라. 이유: scope 외.
- React Flow 내부 클래스(`react-flow__node`)에 box-shadow / glow 추가 마라. 이유: anti-slop.
- panOnScroll 비활성화 마라(이전 step에서 활성). 이유: 강의 중 스크롤 휠 패닝 필요.
