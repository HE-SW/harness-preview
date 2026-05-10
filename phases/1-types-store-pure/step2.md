# Step 2: persistence

## 읽어야 할 파일

- `CLAUDE.md`
- `docs/ARCHITECTURE.md` (의존 방향, persistence write 정책)
- `src/types/board.ts`, `src/types/board.schemas.ts` (step 0)
- `src/lib/validateImport.ts` (step 1)
- `/Users/khaneol/.claude/plans/image-1-snug-wilkinson.md` "아키텍처 핵심 룰" 섹션 (Persistence / Quota / Migration)

## 배경

step 1이 pure 헬퍼를 만들었다. 이 step은 localStorage 접근 + schema migration 인프라를 만든다. **store는 다음 step**에서 이걸 import 해서 사용한다.

## 작업

### 1) `src/lib/migrations.ts`

```ts
import type { ExportEnvelope, Board, PaletteItem } from '@/types/board';

export type RawState = {
  schemaVersion: number;
  current?: unknown;
  presets?: unknown;
  userPalette?: unknown;
};

/**
 * version → migrator 레지스트리. version=N인 데이터를 N+1로 변환.
 * 본 phase에서는 v1이 최신이므로 빈 객체. 향후 v2 추가 시 1: (raw)=>raw' 등록.
 */
export const migrations: Record<number, (raw: RawState) => RawState> = {};

/**
 * raw state의 schemaVersion부터 SCHEMA_VERSION_CURRENT까지 순차 적용.
 */
export function migrate(raw: RawState): RawState;
```

### 2) `src/lib/persistence.ts`

```ts
import type { Board, PaletteItem } from '@/types/board';

export const LS_KEYS = {
  current:  'board:current',
  presets:  'board:presets',
  userPalette: 'palette:user',
  presetPanelCollapsed: 'ui:presetPanelCollapsed',
  onboardingDismissed: 'onboarding:dismissed',
} as const;

export type LoadedState = {
  current: Board | null;
  presets: Board[];
  userPalette: PaletteItem[];
  presetPanelCollapsed: boolean;
  onboardingDismissed: boolean;
  recoveredFromCorrupt: boolean; // true면 호출측이 토스트 띄울 책임
};

/**
 * 모든 read를 try/catch. parse 실패 시 그 키만 'board:corrupt:<ts>'로 백업하고 빈 값 반환,
 * recoveredFromCorrupt=true 마킹.
 * schemaVersion mismatch는 migrate()로 자동 변환 시도. 실패 시 위와 동일.
 */
export function loadAll(): LoadedState;

/**
 * 호출 측에서 commit-only로 호출. 내부에서 300ms debounce는 하지 않는다 — debounce는 store에서.
 * 이 함수는 단발성 sync 쓰기. QuotaExceededError는 throw (store가 catch해 토스트).
 */
export function saveCurrent(board: Board | null): void;
export function savePresets(presets: Board[]): void;
export function saveUserPalette(items: PaletteItem[]): void;
export function saveUiPanelCollapsed(v: boolean): void;
export function saveOnboardingDismissed(v: boolean): void;

/**
 * 다른 탭이 같은 key 변경 시 호출자에게 알림. 호출 즉시 unsubscribe 함수 반환.
 */
export function subscribeStorageEvent(
  handler: (key: string, newValue: string | null) => void
): () => void;

/**
 * 손상 백업 키(`board:corrupt:*`)를 모두 나열. 디버그/UI에서 노출 가능.
 */
export function listCorruptBackups(): string[];
```

내부에서 `migrate`를 import하고, 모든 read는 schemaVersion을 envelope wrapper로 보존:

```
localStorage[board:current]   = JSON.stringify({ schemaVersion: 1, data: Board })
localStorage[board:presets]   = JSON.stringify({ schemaVersion: 1, data: Board[] })
localStorage[palette:user]    = JSON.stringify({ schemaVersion: 1, data: PaletteItem[] })
```

### 3) Vitest (`src/lib/__tests__/persistence.test.ts`, `src/lib/__tests__/migrations.test.ts`)

- persistence:
  - round-trip: save → load 동일 객체
  - 빈 localStorage → null/[] defaults + recoveredFromCorrupt=false
  - 잘못된 JSON 주입 → recoveredFromCorrupt=true + corrupt 백업 키 생성
  - QuotaExceededError 시뮬레이션 → save 함수가 throw (mock으로 setItem이 throw)
  - storage event 구독 → 핸들러가 호출됨
- migrations:
  - 빈 레지스트리 + schemaVersion=1 → 그대로 반환
  - schemaVersion=0 + dummy migrator(0→1) 등록 → 변환됨

JSDOM 환경에서 `vi.spyOn(Storage.prototype, 'setItem')` 등으로 quota 시뮬레이트.

## Acceptance Criteria

```bash
test -f src/lib/persistence.ts
test -f src/lib/migrations.ts
test -f src/lib/__tests__/persistence.test.ts
test -f src/lib/__tests__/migrations.test.ts
npm run typecheck
npm run lint
npx vitest run src/lib/__tests__/persistence.test.ts src/lib/__tests__/migrations.test.ts
```

## 검증 절차

1. AC 모두 통과 (Vitest green).
2. ESLint `no-restricted-imports` 룰이 `persistence.ts`/`migrations.ts`에서 store import를 막는지 확인 (코드상 store import 없음).
3. `phases/1-types-store-pure/index.json` step 2 업데이트.

## 금지사항

- store나 io를 import 하지 마라. 이유: 의존 방향 `persistence ← store`.
- debounce 로직을 persistence 안에 넣지 마라. 이유: store의 책임.
- React Flow 코드를 import 하지 마라. 이유: 의존 분리.
- 손상 데이터를 자동 폐기하지 마라(반드시 `board:corrupt:<ts>` 백업). 이유: 사용자 작업물 잠재적 복구.
- 200줄 넘기지 마라(테스트 제외).
