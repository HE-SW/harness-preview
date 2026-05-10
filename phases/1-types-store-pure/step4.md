# Step 4: io-and-statics

## 읽어야 할 파일

- `CLAUDE.md`
- `docs/ARCHITECTURE.md` (`io.ts`는 store 미참조 — pure data in/out)
- `src/types/board.ts`, `src/types/board.schemas.ts`
- `src/lib/validateImport.ts`, `src/lib/reIdSubgraph.ts` (step 1)
- `src/lib/persistence.ts` (step 2 — 키 이름만 참고, import 금지)

## 배경

이 step은 (a) JSON envelope 직렬화/역직렬화 `io.ts`, (b) 정적 카탈로그/i18n/상수 파일들을 만든다. `io.ts`는 **데이터 in / 데이터 out**만 — store도 persistence도 import 하지 않는다. UI가 `io.export(state)`를 호출하고 결과 파일을 트리거하는 구조.

## 작업

### 1) `src/lib/io.ts`

```ts
import type { Board, PaletteItem, ExportEnvelope } from '@/types/board';
import { reIdEnvelope } from './reIdSubgraph';
import { validateImport, type ImportResult } from './validateImport';

/**
 * 현재 보드 + 프리셋 + 사용자 팔레트로 envelope 만든다.
 * now()는 인자로 받지 않고 내부 Date.now() 호출 — 이 함수는 비결정적 OK.
 */
export function buildEnvelope(input: {
  current: Board | null;
  presets: Board[];
  userPalette: PaletteItem[];
}): ExportEnvelope;

/**
 * envelope를 indent된 JSON 문자열로 반환.
 */
export function serializeEnvelope(env: ExportEnvelope): string;

/**
 * 파싱+검증+(옵션)머지 시 id 재발급까지 한번에.
 * mode='replace' → 그대로 반환 (caller가 store를 통째로 교체)
 * mode='merge'   → reIdEnvelope 후 반환 (caller가 자기 state에 append)
 */
export function parseImport(
  raw: string | unknown,
  mode: 'replace' | 'merge'
): ImportResult;
```

### 2) `src/lib/palette-catalog.ts`

```ts
import type { PaletteItem, FixedPaletteKey } from '@/types/board';

/**
 * 고정 팔레트. 이미지 참조의 좌측 카드 셋을 본떠 정의.
 * group 순서: '구역', '컴퓨터/도구', '문서/사용자/이미지', '연결', '샘플 화면'.
 * 사용자 팔레트는 store.userPalette에서 별도. UI(Phase 3)에서 둘을 합쳐 렌더.
 */
export const FIXED_PALETTE: PaletteItem[];

/**
 * 그룹 표시 순서 + 라벨 한국어.
 */
export const PALETTE_GROUPS: { id: string; label: string; }[];
```

각 항목의 `iconKind: 'emoji'` + `iconValue`(이모지)로 시작 — 이미지 아이콘은 phase 9의 사용자 추가에서. 필요하면 inline SVG dataURL 도 OK이나 본 step에서는 이모지로 충분 (예: 🟦 구역, 🖥️ 컴퓨터, 💾 소스코드, 🅿️ 프로그램, 🌐 Chrome, 📄 문서, 👤 사용자, 🖼️ 이미지, ➡️ 직선, 📡 네트워크, ⋯ 점선, ↩️ 커브, 🌐 브라우저샘플, 🎮 게임샘플, 📰 문서샘플, 💻 터미널샘플).

### 3) `src/lib/edge-variants.ts`

```ts
import type { EdgeVariant } from '@/types/board';

export const EDGE_VARIANTS: { id: EdgeVariant; label: string; description: string; }[];
//   straight   '직선'    '흐름/호출'
//   network    '네트워크' '패킷 전송'
//   dotted     '점선'    '연관/참조'
//   curve-loop '커브'    '루프'
```

### 4) `src/lib/i18n/ko.ts`

```ts
/**
 * 모든 사용자에게 보이는 한국어 문자열을 한 곳에 모은다.
 * 라이브러리는 도입하지 않는다 — 단일 객체.
 */
export const ko = {
  app: { title: '루키스의 그림판', untitled: '제목 없음' },
  header: { newBoard: '새 칠판', save: '저장', saveAs: '다른 이름으로 저장', import: '불러오기', export: '내보내기', undo: '되돌리기', redo: '다시하기', shortcuts: '단축키', togglePanel: '패널 토글', viewportWarn: '데스크톱 1280px 이상 권장' },
  preset: { empty: '저장된 칠판이 없습니다', sectionTitle: '프리셋' },
  canvas: { empty: '좌측에서 요소를 끌어 놓으세요', dropTargetHint: '컨테이너 위로 놓으면 그룹에 추가됩니다' },
  dialog: { dirty: { title: '저장하지 않은 변경 사항이 있습니다', save: '저장하고 시작', discard: '버리고 시작', cancel: '취소' }, deleteContainer: { title: '컨테이너 삭제', cascade: '자식까지 모두 삭제', detach: '자식은 보존', cancel: '취소' } },
  toast: { saved: '저장됨', updated: '업데이트됨', importOk: '불러왔습니다', importFail: '잘못된 파일입니다', quota: '용량이 부족합니다 — 내보내기 후 정리해주세요', recovered: '이전 세션 데이터를 복구하지 못해 백업 후 새로 시작합니다', crash: '캔버스가 충돌했습니다 — 상태를 백업했습니다' },
  palette: { add: '내 요소 추가', emoji: '이모지', image: '이미지 (≤ 32KB)' },
  onboarding: { step1: '왼쪽에서 요소를 드래그해 칠판에 놓으세요', step2: '노드의 핸들을 드래그해 다른 노드와 연결합니다', step3: '저장 버튼으로 우측 프리셋에 보관할 수 있어요', skip: '건너뛰기', next: '다음', done: '시작하기' },
} as const;
```

### 5) `src/lib/__tests__/io.test.ts`

- buildEnvelope(state) → schemaVersion 1, exportedAt is number
- serializeEnvelope → JSON.parse round-trip
- parseImport(invalid) → ok:false
- parseImport(valid, 'merge') → 새 id (원본 id와 다름)
- parseImport(valid, 'replace') → 원본 id 그대로

## Acceptance Criteria

```bash
test -f src/lib/io.ts
test -f src/lib/palette-catalog.ts
test -f src/lib/edge-variants.ts
test -f src/lib/i18n/ko.ts
test -f src/lib/__tests__/io.test.ts
npm run typecheck
npm run lint
npx vitest run src/lib/__tests__/io.test.ts
```

## 검증 절차

1. AC 통과.
2. `io.ts`에서 `store.ts`나 `persistence.ts` import 없는지 grep으로 확인 (`! grep -E "from '@/lib/(store|persistence)'" src/lib/io.ts`).
3. `phases/1-types-store-pure/index.json` step 4 업데이트.

## 금지사항

- `io.ts`에서 `store`/`persistence`/`migrations`를 import 하지 마라. 이유: pure 레이어 — UI가 양쪽 호출.
- 다국어 라이브러리(i18next, next-intl) 도입 마라. 이유: scope 외, 단일 객체로 충분.
- 카탈로그에 색상이나 폰트 같은 디자인 토큰을 넣지 마라. 이유: UI-GUIDE의 단일 출처.
- 카탈로그에 사용자 정의 항목을 inline으로 넣지 마라(예: `'user:foo'`). 이유: user 항목은 store.userPalette + phase 9.
