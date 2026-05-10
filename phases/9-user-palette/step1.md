# Step 1: catalog-merge

## 읽어야 할 파일

- `CLAUDE.md`
- `src/lib/palette-catalog.ts`
- `src/lib/store.ts` (`addUserPaletteItem`, `removeUserPaletteItem`, `selectUserPalette`)
- `src/components/Palette.tsx` (`onRequestAddUserItem` prop)
- `src/components/PaletteAddDialog.tsx` (step 0)
- `src/lib/persistence.ts` (`saveUserPalette` — 즉시 저장 정책)

## 배경

이 step은 step 0의 다이얼로그를 좌측 팔레트 패널에 잇고 사용자 항목을 '내 팔레트' 그룹에 렌더링한다. quota 초과 시 토스트.

## 작업

### 1) `Palette.tsx` 확장

- `+ 내 요소 추가` 버튼 클릭 → `<PaletteAddDialog>` open (로컬 state)
- 다이얼로그 onConfirm → `useApp.getState().addUserPaletteItem(item)` → 토스트 "추가됨"
- store의 `addUserPaletteItem`는 persistence.saveUserPalette 호출. QuotaExceededError catch 시 store에서 throw 재던지고, UI catch → 토스트 `ko.toast.quota`.
- 사용자 항목 그리드 카드: hover 시 우상단에 작은 `×` 버튼 → `removeUserPaletteItem(key)` (확인 dialog 없이 즉시. 단, 2 사용자 카드일 때만 — 너무 잦은 실수 방지를 위해 단축 X 버튼은 1초 hover 후 보이게 `transition-opacity`는 anti-slop 위반 → 단순히 `opacity-0 group-hover:opacity-100`)

### 2) Drag start 동일

사용자 카드도 `onDragStart` 페이로드는 `paletteKey: 'user:xxx'`. Canvas의 dnd hook은 fixed/user 둘 다 처리(이미 `findPaletteItem(key, userPalette)` 사용).

### 3) 영속

`addUserPaletteItem`/`removeUserPaletteItem` 직후 즉시 persistence.saveUserPalette. quota error 시 throw → UI 처리.

## Acceptance Criteria

```bash
grep -q "PaletteAddDialog" src/components/Palette.tsx
grep -q "addUserPaletteItem" src/components/Palette.tsx
grep -q "removeUserPaletteItem" src/components/Palette.tsx
grep -q "ko.toast.quota" src/components/Palette.tsx
npm run lint
npm run typecheck
npm run build
```

수동:
- '내 요소 추가' → 이모지 🦊, 라벨 '여우' → 추가 → '내 팔레트' 그룹에 카드.
- 새로고침 → 유지.
- 카드 드래그 → 캔버스에 노드로 생성, 아이콘은 이모지로 표시.
- '×' 클릭 → 사라짐, 영속.
- localStorage를 의도적으로 5MB 가까이 채운 뒤 추가 → quota 토스트.

## 검증 절차

1. AC 통과 + 수동 OK.
2. `phases/9-user-palette/index.json` step 1 업데이트.

## 금지사항

- 사용자 항목 삭제 시 confirm dialog 추가 마라. 이유: × 직접 삭제 단순. 실수 시 zundo가 아닌 별도 복구 — 사용자가 다시 추가하면 되는 경량 데이터.
- 사용자 항목을 fixed 카탈로그에 mutate 마라. 이유: 단일 출처 분리.
- 동일 라벨 중복 차단 마라. 이유: 사용자 자유. key는 uuid라 충돌 없음.
- 이미지 base64를 다른 곳(예: store.current 노드 data)에 복제 저장 마라. 이유: paletteKey만 저장하고 렌더 시 카탈로그에서 lookup.
