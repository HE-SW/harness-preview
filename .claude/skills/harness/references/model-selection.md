# 모델 선택 가이드

phase index.json의 `model` 필드 결정용. step 분해를 끝낸 직후, 이 phase의 난이도를 보고 한 번 정한다.

## 선택 기준

| 모델 | 적합한 phase 특성 |
|------|------------------|
| `sonnet` (기본) | step이 잘 분해되어 있음 / AC가 실행 가능한 커맨드 / 코드베이스가 익숙한 프레임워크 / 시그니처 수준 지시로 충분 |
| `opus` | 새로운 아키텍처 결정이 step 안에 남아있음 / 외부 시스템과의 모호한 통합 / 대규모 마이그레이션·리팩터링 / step 1회 실패 비용이 큰 작업 |
| `haiku` | 보일러플레이트 생성 / 파일 단순 변환 / 트리비얼한 setup |

## 실용 휴리스틱

- **잘 설계된 step은 sonnet으로 충분**. harness 설계 원칙(scope 최소화, 시그니처 수준 지시, 실행 가능 AC)을 충실히 지켰다면 sonnet의 sweet spot.
- **재시도 비용이 크면 opus**. 1회 시도가 길거나(빌드/마이그레이션), 결과가 외부에 영향을 주면 1회 성공률 높은 opus가 총비용 우위.
- **의심스러우면 sonnet으로 시작**. 실패하면 user가 `--model opus`로 재실행 가능.

## 우선순위

execute.py의 모델 해석 순서:
1. CLI `--model` 플래그
2. phase index.json의 `model` 필드
3. 기본값 `sonnet`

## 표기

- 별칭(`sonnet`, `opus`, `haiku`)이나 정식 ID(`claude-sonnet-4-6`, `claude-opus-4-7`) 둘 다 허용.
- 별칭이 안정적이고 짧으니 권장.

## 안티패턴

- 모든 phase에 일괄 `opus` 박기 → 비용·속도 손해. step이 잘 분해됐다면 sonnet으로 충분.
- step별로 다른 모델을 섞어쓰려 하기 → 현재 schema는 phase 단위만 지원. 필요하면 phase를 쪼개라.
