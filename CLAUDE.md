# CLAUDE.md

## 프로젝트: {프로젝트명}

목표 : {목표작성}

## 기술 스택

- {프레임워크 (예: Next.js 15)}
- {언어 (예: TypeScript strict mode)}
- {스타일링 (예: Tailwind CSS)}

## 아키텍처 규칙

- CRITICAL: {절대 지켜야 할 규칙 1 (예: 모든 API 로직은 app/api/ 라우트 핸들러에서만 처리)}
- CRITICAL: {절대 지켜야 할 규칙 2 (예: 클라이언트 컴포넌트에서 직접 외부 API를 호출하지 말 것)}
- {일반 규칙 (예: 컴포넌트는 components/ 폴더에, 타입은 types/ 폴더에 분리)}

## 개발 프로세스

- CRITICAL: 새 기능 구현 시 반드시 테스트를 먼저 작성하고, 테스트가 통과하는 구현을 작성할 것 (TDD)
- 커밋 메시지는 conventional commits 형식을 따를 것 (feat:, fix:, docs:, refactor:)

## 명령어 {프로젝트에 맞게 작성할 것}

    npm run dev # 개발 서버
    npm run build # 프로덕션 빌드
    npm run lint # ESLint
    npm run test # 테스트

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
