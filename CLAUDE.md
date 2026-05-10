# CLAUDE.md

## 프로젝트: 루키스의 그림판 (lukis-drawing-board)

목표 : 강의용 드래그 앤 드롭 다이어그램 도구. 좌측 팔레트 → 가운데 React Flow 칠판 → 우측 프리셋. 컨테이너 중첩, 4종 연결선, JSON import/export, localStorage 영속.

## 기술 스택

- Next.js 15 (App Router)
- TypeScript strict
- Tailwind CSS
- `@xyflow/react` (React Flow)
- `zustand` + `zundo` (state + history)
- `zod` (import 검증)
- `vitest` (단위 테스트)

## 아키텍처 규칙

- CRITICAL: `src/{app,components,types,lib,hooks}` 구조 유지. 의존 방향 `ui → store → {persistence, io, migrations} → types`. ESLint `no-restricted-imports`로 강제.
- CRITICAL: `io.ts`는 store 미참조(pure). localStorage 접근은 `useEffect` 내부만. SSR boundary 명시.
- 컴포넌트는 `components/` 폴더에, 타입은 `types/` 폴더에 분리. React Flow는 controlled (`nodes={fromStore}`). 내부 `useNodesState` 금지.

## 개발 프로세스

- CRITICAL TDD 부분 waiver: 핵심 로직 한정 적용. 적용 대상: `src/lib/{reparent,cascadeDelete,reIdSubgraph,validateImport,persistence,migrations}.ts`. UI / React Flow 통합 / hook은 수동 시나리오 검증.
- 커밋 메시지는 conventional commits 형식을 따를 것 (feat:, fix:, docs:, refactor:)

## 명령어

    npm run dev        # 개발 서버
    npm run build      # 프로덕션 빌드
    npm run lint       # ESLint
    npm run typecheck  # TypeScript 검사
    npm run test       # 테스트

## 클로드 코드 사용시 주의사항

이 프로젝트는 **코딩 가이드**를 적용한다. 클로드 코드의 기본 동작(빠른 실행, 자율 수정)과 충돌이 발생할 수 있으므로 반드시 숙지한다.

상세 내용 : [`docs/rules/coding-guidelines.md`](docs/rules/coding-guidelines.md)

**핵심 규칙 요약**

- **코드 타이핑 전에 생각부터 (Think Before Coding)**
- **단순하게 먼저 (Simplicity First)**
- **수술처럼 정밀하게 (Surgical Changes)**
- **목표 중심 실행 (Goal-Driven Execution)**

**Harness 워크플로우 강제**

- CRITICAL: 새 기능/리팩터링은 직접 코딩으로 시작하지 말 것. 반드시 `harness` skill을 호출해
  phase/step으로 분해한 뒤 `python3 scripts/execute.py <task>`로 실행한다.
- CRITICAL: Plan Mode 종료 후에도 동일. 플랜이 승인됐다고 바로 코드를 작성하지 말고,
  먼저 `harness` skill을 호출해 `phases/<task>/` 파일을 만들고 사용자 승인을 받은 뒤 실행한다.
- 예외: 최초 /docs 작업시, 단일 파일 typo 수정, 1-2줄 버그 핫픽스, 문서 수정처럼 phase가 과한 작업은 직접 수정 가능.
