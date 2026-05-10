# Step 0: project-init

## 읽어야 할 파일

- `CLAUDE.md` (프로젝트 루트)
- `docs/ARCHITECTURE.md` (디렉토리 구조 규칙)
- `docs/UI-GUIDE.md` (anti-slop 가이드)
- `docs/rules/coding-guidelines.md` (Think Before Coding / Simplicity / Surgical / Goal-driven)

## 배경

프로젝트는 Next.js (App Router) + React + TypeScript strict + Tailwind + React Flow 기반 강의용 다이어그램 도구다. 이 step은 빌드 시스템과 설정 파일만 만든다. 의존성 설치와 src 디렉토리는 step 1에서, 문서 채우기는 step 2에서 다룬다.

## 작업

루트에 다음 설정 파일을 생성한다. 코드를 다 적지 말고 합리적 기본값으로 채워라.

1. `package.json`
   - `name`: `lukis-drawing-board`
   - `private`: true
   - scripts: `dev` / `build` / `start` / `lint` / `typecheck` (`tsc --noEmit`) / `test` (`vitest run`) / `test:watch` (`vitest`)
   - dependencies / devDependencies 필드만 비어있는 객체로 두기 (실제 설치는 step 1)
2. `tsconfig.json` — Next.js 15 + App Router 권장 + **`strict: true`**, `paths`: `@/*` → `./src/*`
3. `next.config.ts` — 기본
4. `tailwind.config.ts` — `content: ['./src/**/*.{ts,tsx}']`. theme.extend 비워두기
5. `postcss.config.js` — tailwindcss + autoprefixer
6. `vitest.config.ts` — environment `jsdom`, `globals: true`, alias `@/* → src/*`
7. `.gitignore` — Next.js 표준 (`.next/`, `node_modules/`, `.env*.local`, `dist/`, `coverage/`)
8. `.eslintrc.json` — `next/core-web-vitals`, `@typescript-eslint/recommended` + 다음 룰:
   ```
   "no-restricted-imports": ["error", {
     "patterns": [
       { "group": ["**/store"], "importNames": ["*"], "message": "io.ts/persistence.ts/migrations.ts는 store를 직접 import 하지 마라. 의존 방향: ui → store → {persistence, io, migrations} → types" }
     ]
   }]
   ```
   (단, 위 룰은 `src/lib/io.ts`, `src/lib/persistence.ts`, `src/lib/migrations.ts` 파일에만 overrides로 적용)

## Acceptance Criteria

```bash
test -f package.json && cat package.json | python3 -c "import json,sys; d=json.load(sys.stdin); assert d['name']=='lukis-drawing-board'; assert 'dev' in d['scripts']"
test -f tsconfig.json && cat tsconfig.json | python3 -c "import json,sys; d=json.load(sys.stdin); assert d['compilerOptions']['strict']==True"
test -f next.config.ts
test -f tailwind.config.ts
test -f postcss.config.js
test -f vitest.config.ts
test -f .gitignore
test -f .eslintrc.json
```

## 검증 절차

1. 위 AC 커맨드를 모두 실행한다 (모두 exit 0).
2. 디렉토리 구조 확인: 루트에 위 파일만 추가되었고 `src/` 디렉토리는 아직 만들지 않았다.
3. 결과에 따라 `phases/0-scaffold/index.json`의 step 0을 업데이트:
   - 성공 → `"status": "completed"` + `"summary": "build configs (Next.js + TS strict + Tailwind + Vitest + ESLint) 생성, 의존성 설치 전"`
   - 실패 → `"status": "error"` + `"error_message"`
   - 차단 → `"status": "blocked"` + `"blocked_reason"`

## 금지사항

- `npm install` / `pnpm install` 실행하지 마라. 이유: 의존성 설치는 step 1에서 한 번에.
- `src/` 디렉토리나 그 안의 파일을 만들지 마라. 이유: app shell은 step 1.
- `CLAUDE.md`, `docs/*` 수정하지 마라. 이유: 문서 채우기는 step 2.
- 의존성 버전을 임의로 잠그지 마라(빈 `dependencies`/`devDependencies`로 둘 것). 이유: step 1에서 `npm install` 시 최신 호환 버전 자동 결정.
- 추가 설정 파일(.prettierrc 등) 만들지 마라. 이유: 이 프로젝트 scope 외.
