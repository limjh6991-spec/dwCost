# HQ 모델표기 도우코드 전환 — 운영 반영 계획서
작성 2026-10-22 (개정 2026-10-23) · 대상 DB `도우제조원가시스템`(운영, 10.100.40.17,14233) · 범위 HQ(SITE='HQ')

## 1. 목표 / 원칙
- HQ 화면 모델 표기를 **끝자리 자른 도우모델(818V) → 완전 도우코드/품번(818VP·818VT)** 으로 전환.
- **결산 그레인·금액은 전혀 바꾸지 않는다.** `도우코드`는 원가행의 **비집계 "라벨" 컬럼**(pass-through). 집계/배부/이월 산식 무변경.
- 리포트는 표기만 `COALESCE(NULLIF(도우코드,''), 도우모델)` — 코드가 있으면 완전코드, 없으면 기존 도우모델.
- **전략 B(그레인 재설계) 아님.**

## 2. 두 구간(확정 — 방법 ②)
| 구간 | 방식 |
|---|---|
| **1~9월 (마감·결산완료)** | `UP_DOI_FILL_DWCODE` 월별 1회 **수동 EXEC**(4테이블 일괄, 도우코드만 UPDATE, 마감 무관·재결산 아님) |
| **10월~ (신규 결산)** | **COST·STOCK_COST = 프로시저 인라인**(결산이 직접 채움, `04` 참조) + **판관비(SLCO·SMCE) = 결산 끝 `UP_DOI_FILL_DWCODE`** (인라인 취약) |

→ 10월~ 는 COST/STCO가 **자기 프로시저에서 직접** 채우고(별도 fill 불필요), 판관비만 끝에 fill. 과거월은 `UP_DOI_FILL_DWCODE`(4테이블) 백필.

## 3. 채움 로직 / 원천 (UP_DOI_FILL_DWCODE, 4개 테이블)
| 테이블 | 용도 | 도우코드 원천 | 키 |
|---|---|---|---|
| DOI_STCO | 매출원가·제품재고 | `DOI_STOCK.MODEL_TYPE`(품번) | (구분[suffix파생], 품명=MODEL) 1:1 |
| DOI_COST | 재료비·제조경비 | 카세트=MODEL / 비카세트=생산수불 도우코드(818VT carve-out) | (구분, mk) 1:1 |
| DOI_SLCO | 매출원가 거래처별 | DOI_STCO 상속 | (구분, MODEL) |
| DOI_SMCE_COST | 판관비 집계(화면 원천) | DOI_STCO 상속 | (구분, model) |
- 1:1 가드(`COUNT(DISTINCT)=1 else NULL`): 카세트 다변종·미래 D/T 공존 등 다대1은 미기입(NULL→리포트 도우모델 폴백). 틀린 코드 생성 0.
- 원장상계(DOI_원장상계)는 이미 full 도우코드 → 불필요. DOI_SCOF 실효 낮음(생략 가능).

## 4. 개발서버 검증 결과 (근거, 202609)
- `UP_DOI_FILL_DWCODE` 실행: 4개 테이블 **공통컬럼 CHECKSUM = 운영 동일(값 불변)**, 도우코드 채움 DOI_COST 100%·STCO 99%·SLCO 99%·SMCE 100%, 818VP/818VD/818VT 정확.
- 결산 체인 재실행(dt 리다이렉트)도 운영 수치 CHECKSUM 완전 재현 → 10월~ 재실행·배포 안전.
- (인라인 주입 B도 COST/STCO는 값중립이나 SALE_COST는 취약 → fill 방식으로 통일.)

## 5. 반영 순서
> 운영 쓰기는 SSMS 수동(공유DB). 라이브 프로시저는 OBJECT_DEFINITION 최신본 위에서 수정.

- **Phase 0 — 백업**: 대상 4테이블 스냅샷 + 리포트 프로시저 OBJECT_DEFINITION 백업.
- **Phase 1 — 컬럼 ADD**: `01_alter_add_도우코드.sql` (DOI_COST/STCO/SLCO/SMCE_COST, 도우코드 nvarchar/varchar NULL). SCOF 선택.
- **Phase 1b — fill 프로시저 생성**: `UP_DOI_FILL_DWCODE.sql`.
- **Phase 2 — 과거월 백필**: `02_backfill_과거월.sql` (1~9월 EXEC 루프 + 채움률 확인).
- **Phase 3 — 10월~ 자동 채움**: COST·STOCK_COST 인라인(`04_inline_UP_DOI_COST_STOCK_COST.md`의 find/replace를 라이브 정의에 적용) + 판관비 fill(결산 끝 `EXEC UP_DOI_FILL_DWCODE`). `03_10월이후_자동연결_및_리포트표기.md`.
- **Phase 4 — 리포트 표기**: 리포트 프로시저 모델 라벨을 `COALESCE(NULLIF(도우코드,''),도우모델)` 로(ALTER만, 키는 유지). 동적 피벗 매퍼 + jar.
- **Phase 5 — 프론트**: 행라벨 화면은 JS 무변경. 동적 피벗(C0009005/08/06) 매퍼+jar. ★C0007011 검산은 표기만 도우코드, 역산조인은 도우모델 유지.
- **Phase 6 — 검증**: 반영 전후 tie-out(매출액·매출원가·판관비·총원가·영업이익 동일) + 완전코드 표기 샘플 확인.

## 6. 위험·주의
| 위험 | 대응 |
|---|---|
| 값 변동 우려 | fill은 도우코드만 UPDATE → 구조적 값 불변(개발 실증). |
| 마감월 재실행 차단 | 과거월은 **백필만**(fill=UPDATE, 재결산 아님). |
| 다대1(카세트·미래 D/T) silent 오라벨 | COUNT(DISTINCT)=1 가드 → 틀리면 NULL(도우모델 폴백). |
| 리포트 코드 GROUP BY 키 사용 | 표기 전용. 키는 (구분,도우모델) 유지. |
| 라이브 프로시저 stale | OBJECT_DEFINITION 최신본 위에서만 수정. |
| `도우코드` 컬럼 ADD 선행 | 미추가 시 fill UPDATE 대상 컬럼 없음(01 먼저). |

## 7. 롤백 / 범위 밖
- 롤백 `99_rollback.sql`(자동연결 해제→리포트 복원→백필 되돌리기→fill프로시저 DROP→컬럼 DROP).
- VN(SITE='VN')은 별건(이미 도우코드 전환). SCOF 생략 가능(원장상계가 full코드).

## 파일
- `01_alter_add_도우코드.sql` — 컬럼 ADD
- `UP_DOI_FILL_DWCODE.sql` — 통합 채움 프로시저(과거월·10월~ 공용)
- `02_backfill_과거월.sql` — 1~9월 백필(EXEC 루프)
- `03_10월이후_자동연결_및_리포트표기.md` — 10월~ 채움 방식(인라인+판관비fill) + 리포트 COALESCE
- `04_inline_UP_DOI_COST_STOCK_COST.md` — 10월~ COST·STOCK_COST 인라인 편집(검증된 find/replace 11건)
- `99_rollback.sql` — 롤백
