# Step 0: add-dialog

## 읽어야 할 파일

- `CLAUDE.md`
- `docs/UI-GUIDE.md`
- `src/types/board.ts` (`PaletteItem`, `UserPaletteKey`)
- `src/lib/store.ts` (`addUserPaletteItem`)
- `src/components/ConfirmDialog.tsx`
- `src/lib/i18n/ko.ts`

## 배경

이 step은 사용자가 새 팔레트 항목(이모지 또는 작은 이미지)을 추가하는 다이얼로그를 만든다. 이미지 정규화/사이즈 가드 포함.

## 작업

### 1) `src/lib/imageNormalize.ts`

```ts
/**
 * 64x64로 contain 다운스케일 후 PNG base64 dataURL 반환.
 * 결과 base64 길이가 32KB 초과 시 throw('OVERSIZE').
 * 입력은 File (image/* 만). 그 외 throw('INVALID_TYPE').
 * Canvas 2D + drawImage 사용.
 */
export async function normalizeIconImage(file: File): Promise<string>;
```

테스트는 JSDOM에서 canvas 미지원 → 본 함수는 수동 검증으로 충분. (선택적으로 `vitest-canvas-mock`)

### 2) `src/components/PaletteAddDialog.tsx`

```tsx
'use client';
export type PaletteAddDialogProps = {
  open: boolean;
  onCancel: () => void;
  onConfirm: (item: PaletteItem) => void;
};
export function PaletteAddDialog(p: PaletteAddDialogProps): JSX.Element | null;
```

내부:
- 라벨 input (max 24자)
- 두 탭: '이모지' / '이미지'
  - 이모지: `<input>` (placeholder: 🦊 등 1자), 검증: 적어도 1 codepoint
  - 이미지: `<input type="file" accept="image/*">` 선택 → preview 64x64 → normalize 호출 → base64 결과 미리보기
    - OVERSIZE / INVALID_TYPE → 토스트 + 입력 reset
- 확인 버튼 → key 발급(`'user:' + uuid()`) → `onConfirm({ key, category: 'user', group: '내 팔레트', label, iconKind, iconValue })`

### 3) UI 통합 자리만

본 step은 컴포넌트만 만든다. Palette 패널의 '+ 내 요소 추가' 버튼이 이를 open 하는 wiring은 step 1.

## Acceptance Criteria

```bash
test -f src/lib/imageNormalize.ts
test -f src/components/PaletteAddDialog.tsx
grep -q "normalizeIconImage" src/components/PaletteAddDialog.tsx
npm run lint
npm run typecheck
npm run build
```

수동:
- 임시 dev 버튼으로 다이얼로그 열기 → 이모지 / 이미지 양쪽 시도.
- 1MB 이미지 업로드 → 64x64 PNG로 다운스케일 후 ≤32KB 유지 (대부분 OK). 일부러 큰 PNG가 32KB 넘으면 reject 토스트.

## 검증 절차

1. AC 통과 + 수동 OK.
2. `phases/9-user-palette/index.json` step 0 업데이트.

## 금지사항

- 이미지 라이브러리(sharp, browser-image-compression) 도입 마라. 이유: scope 외, Canvas 2D로 충분.
- SVG 업로드 허용 마라. 이유: XSS 위험. 본 MVP는 raster image만.
- 클립보드 paste로 이미지 입력 받지 마라. 이유: scope 외.
- 이모지를 1자보다 길게 허용 마라. 이유: 카드에 표시 잘림. (선택: 4 codepoint까지 허용해도 OK이지만 1자 강제 단순.)
