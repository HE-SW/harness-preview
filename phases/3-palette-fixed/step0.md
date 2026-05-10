# Step 0: catalog-data

## 읽어야 할 파일

- `CLAUDE.md`
- `docs/UI-GUIDE.md`
- `src/types/board.ts` (`FixedPaletteKey`, `PaletteItem`)
- `src/lib/palette-catalog.ts` (phase 1 step 4 — 이미 존재. 확장 또는 재작성)
- `src/lib/i18n/ko.ts`

## 배경

phase 1 step 4에서 `palette-catalog.ts`의 시그니처를 정의했지만 실제 카탈로그 데이터가 비어있다. 이 step은 화면 좌측 팔레트에 표시될 **고정 카탈로그 데이터**를 채운다.

## 작업

### `src/lib/palette-catalog.ts` 갱신

```ts
export const PALETTE_GROUPS: { id: string; label: string; }[] = [
  { id: 'zone',     label: '구역' },
  { id: 'tool',     label: '컴퓨터/도구' },
  { id: 'media',    label: '문서/사용자/이미지' },
  { id: 'edge',     label: '연결' },
  { id: 'sample',   label: '샘플 화면' },
];

export const FIXED_PALETTE: PaletteItem[] = [
  // zone
  { key: 'zone',        category: 'fixed', group: 'zone',  label: '구역',     iconKind: 'emoji', iconValue: '🟦' },
  // tool
  { key: 'computer',    category: 'fixed', group: 'tool',  label: '컴퓨터',   iconKind: 'emoji', iconValue: '🖥️' },
  { key: 'sourcecode',  category: 'fixed', group: 'tool',  label: '소스코드', iconKind: 'emoji', iconValue: '💾' },
  { key: 'program',     category: 'fixed', group: 'tool',  label: '프로그램', iconKind: 'emoji', iconValue: '🅿️' },
  { key: 'chrome',      category: 'fixed', group: 'tool',  label: 'Chrome',   iconKind: 'emoji', iconValue: '🌐' },
  // media
  { key: 'document',    category: 'fixed', group: 'media', label: '문서',     iconKind: 'emoji', iconValue: '📄' },
  { key: 'user',        category: 'fixed', group: 'media', label: '사용자',   iconKind: 'emoji', iconValue: '👤' },
  { key: 'image',       category: 'fixed', group: 'media', label: '이미지',   iconKind: 'emoji', iconValue: '🖼️' },
  // edge (드래그 시 onDragStart payload는 paletteKey만 — 실제 엣지 생성 흐름은 phase 6)
  // 본 카탈로그에서는 드래그 → 캔버스에 "엣지 시범 노드" 만드는 게 아니라 유저가 시각 참고용으로 보는 슬롯.
  // phase 6에서 카탈로그 항목을 어떻게 활용할지 결정. 본 step은 데이터만 둠.
  { key: 'sample-browser',  category: 'fixed', group: 'sample', label: '브라우저', iconKind: 'emoji', iconValue: '🌐' },
  { key: 'sample-game',     category: 'fixed', group: 'sample', label: '게임화면', iconKind: 'emoji', iconValue: '🎮' },
  { key: 'sample-document', category: 'fixed', group: 'sample', label: '문서뷰',   iconKind: 'emoji', iconValue: '📰' },
  { key: 'sample-terminal', category: 'fixed', group: 'sample', label: '터미널',   iconKind: 'emoji', iconValue: '💻' },
];
```

엣지(`edge` 그룹)의 카탈로그 표현은 phase 6에서 결정 — 본 step은 group 헤더만 있고 항목은 비워두거나 "정보용 비활성 카드"로 표시할 수 있게 group 정의만 둔다. 실제 항목은 추가하지 않는다.

### 카탈로그 sanity 함수

```ts
/**
 * key → PaletteItem (fixed 또는 user). 사용자 팔레트는 외부에서 합쳐 넘긴다.
 */
export function findPaletteItem(
  key: string,
  userPalette: PaletteItem[]
): PaletteItem | undefined;

/**
 * group id로 그룹 라벨.
 */
export function getGroupLabel(groupId: string): string;
```

## Acceptance Criteria

```bash
grep -q "FIXED_PALETTE" src/lib/palette-catalog.ts
node -e "
const { FIXED_PALETTE, PALETTE_GROUPS } = require('./src/lib/palette-catalog.ts');
" 2>/dev/null || true   # ts라서 직접 실행은 안 됨. 대신 typecheck로 검증.
npm run typecheck
npm run lint
npx vitest run --passWithNoTests
```

추가 sanity:
```bash
# 모든 FIXED_PALETTE 항목의 key가 FIXED_PALETTE_KEYS 안에 있는지 (compile-time enforced via type)
# 모든 group이 PALETTE_GROUPS의 id 중 하나인지 → 작성 시 시각 검토
```

## 검증 절차

1. AC 통과.
2. `palette-catalog.ts` 의 `FIXED_PALETTE` 길이가 12 (zone1 + tool4 + media3 + sample4) 이고 모든 key가 `FIXED_PALETTE_KEYS` 와 일치.
3. `phases/3-palette-fixed/index.json` step 0 업데이트.

## 금지사항

- UI 컴포넌트 만들지 마라. 이유: step 1.
- 사용자 팔레트 항목을 inline으로 넣지 마라. 이유: phase 9.
- 그룹 id를 카탈로그 외부(컴포넌트)에 하드코딩하지 마라. 이유: 단일 출처.
- 새 group(예: 'utility') 추가 마라. 이유: 위 5개 외는 scope 변경.
- `paletteKey: string` 으로 type 우회 마라. 이유: literal union 강제.
