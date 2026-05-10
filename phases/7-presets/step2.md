# Step 2: panel-toggle

## 읽어야 할 파일

- `CLAUDE.md`
- `src/lib/store.ts` (`presetPanelCollapsed`, `setPresetPanelCollapsed`)
- `src/components/Shell.tsx` (그리드 분기)
- `src/components/Header.tsx` (`onTogglePanel` 콜백)

## 배경

이 step은 우측 프리셋 패널 collapse 토글과 그 영속을 마무리한다. `]` 단축키 바인딩은 phase 10이지만, 토글 자체는 본 step에서 헤더 버튼으로 노출.

## 작업

### 1) Shell.tsx 그리드 분기

```tsx
const collapsed = useApp(s => s.presetPanelCollapsed);
const cols = collapsed ? 'grid-cols-[240px_1fr_0px]' : 'grid-cols-[240px_1fr_320px]';
```

- collapsed=true 시 우측 컬럼은 `display: none` 또는 width 0 (CSS 명령). PresetPanel은 unmount 또는 hidden — 단순화로 `<aside className={collapsed ? 'hidden' : ''}>`.
- 캔버스 영역이 자연스럽게 확장.

### 2) Header 토글 버튼 wiring

Shell.tsx에서 `<Header onTogglePanel={() => useApp.getState().setPresetPanelCollapsed(!collapsed)} />`.

### 3) 영속

store의 `setPresetPanelCollapsed`는 phase 1 step 3에서 정의됨. persistence는 즉시 저장 (debounce 미적용 — 자주 변하지 않음).

`hydrate` 시 collapsed 상태 복원.

### 4) UX 시각

collapsed 상태에서 헤더 토글 버튼 라벨은 `‹` 또는 `›`로 변경:
- `collapsed ? '‹' : '›'` (또는 SVG)

## Acceptance Criteria

```bash
grep -q "presetPanelCollapsed" src/components/Shell.tsx
grep -q "setPresetPanelCollapsed" src/components/Shell.tsx
grep -q "onTogglePanel" src/components/Shell.tsx
npm run lint
npm run typecheck
npm run build
```

수동:
- 헤더 토글 버튼 → 우측 패널 사라짐, 캔버스 확장. 새로고침 → 상태 유지.

## 검증 절차

1. AC 통과 + 수동 OK.
2. `phases/7-presets/index.json` step 2 업데이트.

## 금지사항

- collapse 시 width 트랜지션 추가 마라. 이유: anti-slop motion 가이드 (fade-in 0.2s 외 금지).
- 키보드 단축키 추가 마라. 이유: phase 10.
- 좌측 팔레트 패널까지 collapse 가능하게 만들지 마라. 이유: scope 외.
- collapsed 상태에서 PresetPanel을 unmount 대신 visibility:hidden로 두지 마라. 이유: 메모리/이벤트 리스너 누수. `hidden` 또는 conditional render.
