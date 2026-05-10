# Step 0: domain-types

## 읽어야 할 파일

- `CLAUDE.md`
- `docs/ARCHITECTURE.md` (의존 방향, 디렉토리)
- `docs/ADR.md` (zod, zustand, React Flow 결정)
- `phases/0-scaffold/index.json` (이전 phase 산출물 확인)

## 배경

phase 0가 코드 스캐폴드와 문서를 채웠다. phase 1은 도메인 타입 → pure 헬퍼 → persistence → store → io 순으로 쌓는다. 이 step은 가장 기초인 **타입 + zod 스키마**만 만든다. store/persistence는 후속 step. 모든 후속 step과 phase가 이 타입을 import해 사용하므로 정확해야 한다.

## 작업

### 1) `src/types/board.ts`

다음 타입을 export 한다 (시그니처/타입만, 런타임 코드 없음).

```ts
// 고정 팔레트 키 (literal union, 런타임 카탈로그는 step 4에서)
// '_FIXED_PALETTE_KEYS' as const 배열로부터 type 유도
export const FIXED_PALETTE_KEYS = [
  'zone',          // 구역 (분할선)
  'computer',      // 컴퓨터 화면
  'sourcecode',    // 소스코드 / VSCode 화면
  'program',       // 프로그램 실행 파일
  'chrome',        // Chrome 웹 브라우저
  'document',      // 문서 (HTML/텍스트)
  'user',          // 사용자/입력자
  'image',         // 이미지 PNG/JPG
  'sample-browser','sample-game','sample-document','sample-terminal'
] as const;
export type FixedPaletteKey = typeof FIXED_PALETTE_KEYS[number];
export type UserPaletteKey = `user:${string}`;
export type PaletteKey = FixedPaletteKey | UserPaletteKey;

export type EdgeVariant = 'straight' | 'network' | 'dotted' | 'curve-loop';
export type HandleId = 'l' | 'r' | 't' | 'b';

export type BoardNode = {
  id: string;
  type: 'item' | 'container';
  parentId?: string;
  paletteKey: PaletteKey;
  label: string;
  position: { x: number; y: number };
  size?: { w: number; h: number };
  zIndex?: number;
  locked?: boolean;
};

export type BoardEdge = {
  id: string;
  source: string; sourceHandle: HandleId;
  target: string; targetHandle: HandleId;
  variant: EdgeVariant;
  label?: string;
};

export type Board = {
  id: string;
  name: string;
  nodes: BoardNode[];
  edges: BoardEdge[];
  createdAt: number;
  updatedAt: number;
};

export type PaletteItem = {
  key: PaletteKey;
  category: 'fixed' | 'user';
  group: string;     // '구역' | '연결' | '샘플 화면' | '내 팔레트' 등
  label: string;
  iconKind: 'emoji' | 'image';
  iconValue: string; // emoji 문자 또는 base64 dataURL
};

export type ExportEnvelope = {
  schemaVersion: 1;
  exportedAt: number;
  boards: Board[];
  userPalette: PaletteItem[];
};

export const SCHEMA_VERSION_CURRENT = 1 as const;
```

### 2) `src/types/board.schemas.ts` (zod 런타임 스키마)

import 검증·persistence 검증용. 위 타입과 1:1 대응.

```ts
import { z } from 'zod';
import { FIXED_PALETTE_KEYS } from './board';

export const handleIdSchema = z.enum(['l','r','t','b']);
export const edgeVariantSchema = z.enum(['straight','network','dotted','curve-loop']);
export const paletteKeySchema = z.union([
  z.enum(FIXED_PALETTE_KEYS),
  z.string().regex(/^user:[A-Za-z0-9_-]+$/)
]);
export const boardNodeSchema: z.ZodType<BoardNode> = z.object({ ... });
export const boardEdgeSchema: z.ZodType<BoardEdge> = z.object({ ... });
export const boardSchema:    z.ZodType<Board>     = z.object({ ... });
export const paletteItemSchema: z.ZodType<PaletteItem> = z.object({ ... });
export const exportEnvelopeSchema = z.object({
  schemaVersion: z.literal(1),
  exportedAt: z.number().int().nonnegative(),
  boards: z.array(boardSchema),
  userPalette: z.array(paletteItemSchema)
});
```

세부 필드는 위 타입 정의와 동일하게 — schema가 type을 위반하지 않게 (`z.ZodType<...>` 또는 `satisfies` 활용).

## Acceptance Criteria

```bash
test -f src/types/board.ts
test -f src/types/board.schemas.ts
npm run typecheck
npm run lint
npx vitest run --passWithNoTests
```

## 검증 절차

1. 위 AC 통과.
2. `src/types/board.ts`에 위 export 모두 존재.
3. `phases/1-types-store-pure/index.json` step 0 업데이트:
   - 성공 → `"status": "completed"` + `"summary": "domain types + zod schemas (Board/Node/Edge/PaletteItem/ExportEnvelope) 정의"`

## 금지사항

- 런타임 로직 추가하지 마라(persistence, store, helpers). 이유: 후속 step.
- 타입에 default 값/팩토리 함수 추가하지 마라. 이유: pure 헬퍼는 step 1, store factory는 step 3.
- React Flow의 `Node`/`Edge` 타입을 직접 export 하지 마라. 이유: 우리 도메인은 React Flow 독립 — 변환은 store에서.
- 외부 라이브러리에서 타입을 import 하지 마라(zod 제외). 이유: types/* 는 가장 하위 레이어, 외부 의존 최소화.
