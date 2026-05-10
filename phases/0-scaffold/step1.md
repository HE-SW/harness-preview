# Step 1: app-shell

## 읽어야 할 파일

- `CLAUDE.md`
- `docs/ARCHITECTURE.md` (디렉토리 구조)
- `docs/UI-GUIDE.md` (anti-slop, 컬러 팔레트, 카드/버튼 base 스타일)
- `package.json` (step 0 산출물)
- `tsconfig.json` (step 0 산출물)
- `tailwind.config.ts` (step 0 산출물)

## 배경

step 0이 빌드 설정을 만들었다. 이 step은 (a) 의존성 설치, (b) `src/app/` 최소 셸 생성, (c) Tailwind 글로벌 CSS 설정을 한다. UI 컴포넌트와 Shell 레이아웃은 phase 2에서 만든다 — 여기서는 페이지가 빈 placeholder만 렌더링하면 된다.

## 작업

### 1) 의존성 설치

`package.json`의 `dependencies`/`devDependencies` 항목을 다음 패키지로 채우고 `npm install`을 실행한다. 버전은 install 시점 최신 안정.

**dependencies**:
- `next`, `react`, `react-dom`
- `@xyflow/react` (React Flow)
- `zustand`, `zundo` (history 미들웨어)
- `zod`
- `uuid`
- `clsx` 또는 `class-variance-authority`(택1, UI 헬퍼)

**devDependencies**:
- `typescript`, `@types/react`, `@types/react-dom`, `@types/node`, `@types/uuid`
- `tailwindcss`, `postcss`, `autoprefixer`
- `eslint`, `eslint-config-next`, `@typescript-eslint/eslint-plugin`, `@typescript-eslint/parser`
- `vitest`, `@vitest/ui`, `jsdom`, `@testing-library/react`, `@testing-library/jest-dom`

### 2) `src/app/` 셸

- `src/app/layout.tsx` — RSC. lang `ko`, `<body>`에 `bg-[#0a0a0a] text-white antialiased`. children render.
- `src/app/page.tsx` — RSC. 한 줄 placeholder `<main className="p-8">루키스의 그림판 (Phase 2에서 Shell 마운트)</main>`.
- `src/app/globals.css` — `@tailwind base; @tailwind components; @tailwind utilities;` + `@import '@xyflow/react/dist/style.css';` 는 **하지 않는다** (React Flow CSS는 phase 4에서 Canvas 컴포넌트에서만 import).

레이아웃은 globals.css를 import 한다.

### 3) `src/` 빈 디렉토리 자리잡기

다음 디렉토리를 빈 `.gitkeep` 파일로 생성하여 후속 phase가 바로 채울 수 있게 한다:

```
src/components/
src/components/nodes/
src/components/edges/
src/lib/
src/lib/i18n/
src/lib/__tests__/
src/types/
src/hooks/
```

### 4) ESLint overrides

step 0이 추가한 `no-restricted-imports` 패턴을 다음 파일에만 적용하도록 `.eslintrc.json`에 `overrides`를 둔다:

```
overrides: [
  { "files": ["src/lib/io.ts", "src/lib/persistence.ts", "src/lib/migrations.ts"], rules: { /* no-restricted-imports rule */ } }
]
```

## Acceptance Criteria

```bash
test -d node_modules
test -f src/app/layout.tsx
test -f src/app/page.tsx
test -f src/app/globals.css
test -d src/components/nodes
test -d src/components/edges
test -d src/lib/i18n
test -d src/lib/__tests__
test -d src/types
test -d src/hooks
npm run lint
npm run typecheck
npm run build
npx vitest run --passWithNoTests
```

## 검증 절차

1. 모든 AC 커맨드 실행. 모두 exit 0.
2. `npm run dev` 가 에러 없이 `localhost:3000`에 placeholder 페이지를 띄우는지 수동 확인 (Ctrl+C로 종료).
3. `phases/0-scaffold/index.json` step 1 업데이트:
   - 성공 → `"status": "completed"` + `"summary": "deps installed, src/app shell + 빈 디렉토리 트리 + ESLint overrides 완료"`
   - 실패/차단 → 해당 status + 사유

## 금지사항

- 컴포넌트 로직을 `src/components/*`에 만들지 마라. 이유: phase 2 이후.
- React Flow CSS를 `globals.css`에 import 하지 마라. 이유: phase 4 Canvas 컴포넌트에서 dynamic+ssr:false로 import해야 SSR 에러 없음.
- `src/app/page.tsx`를 client component로 만들지 마라(`'use client'` 금지). 이유: page는 RSC, Shell은 phase 2에서 client 마운트.
- 의존성에 위 목록 외 패키지 추가하지 마라 (예: framer-motion, headlessui, radix). 이유: scope 외 — 후속 phase에서 필요 시 별도 결정.
- `.gitkeep` 외 파일을 빈 디렉토리에 두지 마라.
