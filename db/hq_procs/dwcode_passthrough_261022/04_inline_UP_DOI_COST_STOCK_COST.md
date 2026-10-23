# Phase 3(10월~) — UP_DOI_COST · UP_DOI_STOCK_COST 인라인 주입 (검증된 편집)

> 결산 시 **프로시저 자체가 `도우코드`를 INSERT에 함께 적재**(별도 fill 불필요). MODEL(도우모델) 그레인·집계·배부·이월 전부 불변 — 개발서버 202609 검증: 값 불변 + 채움 COST 100% / STCO 99%(재공LOSS 1%는 끝 fill 폴백).
> ★ **라이브 우선**: 운영 `OBJECT_DEFINITION` 최신본을 받아 아래 find/replace를 재적용 후 ALTER(repo 사본 배포 금지). 각 old_string은 파일 내 유일(단일행). 선행: 대상 테이블에 `도우코드` 컬럼 ADD(01_alter).

## UP_DOI_COST → DOI_COST.도우코드 (6건)
핵심: 생산수불 맵 CTE(`DWCODE_MAP`, 818VT carve-out) + 메인 비카세트 INSERT에 LEFT JOIN·COALESCE, 카세트 INSERT는 MODEL 직접.
★★ DWCODE_MAP 조인 컬럼은 **반드시 별칭(mgubun/mmodel/mdwcode)** — 미별칭 시 외부 미한정 `구분`/`model` 과 모호(error 209)로 컴파일 실패(실제 겪음).

| # | old_string | new_string |
|---|---|---|
| 1 | `;WITH STUC_UC AS (` | `;WITH DWCODE_MAP AS (SELECT 구분 AS mgubun, CASE WHEN 도우코드=N'818VT' THEN N'818VT' ELSE 도우모델 END AS mmodel, MAX(도우코드) AS mdwcode FROM DOI_PROD_SUBUL WHERE YYYYMM=@YYYYMM AND SITE=@SITE GROUP BY 구분, CASE WHEN 도우코드=N'818VT' THEN N'818VT' ELSE 도우모델 END), STUC_UC AS (` |
| 2 | `,ETC_IN_RMA_QTY ,ETC_IN_RMA_AMT)` | `,ETC_IN_RMA_QTY ,ETC_IN_RMA_AMT, 도우코드)` |
| 3 | `0) as LOSS_DEFECT_AMT, ETC_IN_RMA_QTY, ETC_IN_RMA_AMT` | `0) as LOSS_DEFECT_AMT, ETC_IN_RMA_QTY, ETC_IN_RMA_AMT, COALESCE(dm.mdwcode, a.model) AS 도우코드` |
| 4 | `) a ;` | `) a LEFT JOIN DWCODE_MAP dm ON dm.mgubun = a.구분 AND dm.mmodel = a.model ;` |
| 5 | `UnitCost_YN,LOSS_DEFECT_QTY,LOSS_DEFECT_AMT)` | `UnitCost_YN,LOSS_DEFECT_QTY,LOSS_DEFECT_AMT, 도우코드)` |
| 6 | `END AS LOSS_DEFECT_AMT` | `END AS LOSS_DEFECT_AMT, MODEL AS 도우코드` |

(그 외 DOI_COST INSERT[ADJ_BOH 등]은 미수정 → 도우코드 NULL, 리포트 COALESCE 폴백)

## UP_DOI_STOCK_COST → DOI_STCO.도우코드 (5건)
핵심: MODEL_STOCK CTE에 품번(MODEL_TYPE) 1:1 가드 집계만 추가(GROUP BY 미변경) → EOH CTE 전파 → 최종 INSERT 포함. (선행 탭 포함, 단일행 유일)

| # | old_string | new_string |
|---|---|---|
| 1 | `<TAB>        SUM(ISNULL(a.BOH, 0)) AS BOH,` | `<TAB>        CASE WHEN COUNT(DISTINCT a.MODEL_TYPE)=1 THEN MIN(a.MODEL_TYPE) ELSE NULL END AS 도우코드, SUM(ISNULL(a.BOH, 0)) AS BOH,` |
| 2 | `<TAB>                    A.MODEL,` | `<TAB>                    A.MODEL, a.도우코드,` |
| 3 | `<TAB>        Final_Eoh AS EOH_AMT,` | `<TAB>        도우코드, Final_Eoh AS EOH_AMT,` |
| 4 | `<TAB>    YYYYMM, SITE, SEL_CODE, 구분, MODEL, EXPEN_SEL, EXPEN_SEL명, ACCT_NAME,` | `<TAB>    YYYYMM, SITE, SEL_CODE, 구분, MODEL, 도우코드, EXPEN_SEL, EXPEN_SEL명, ACCT_NAME,` |
| 5 | `<TAB>    ISNULL(EXPEN_SEL, 'NONE') AS EXPEN_SEL,` | `<TAB>    도우코드, ISNULL(EXPEN_SEL, 'NONE') AS EXPEN_SEL,` |

`<TAB>` = 라인 선두 탭 1개(원본 그대로 복사). 보조 INSERT(카세트재료비/EXTRA/전량LOSS/RMA)는 미수정 → 그 행 도우코드 NULL(끝 fill 폴백 또는 도우모델 표기).

## 검증 재현(개발)
scratchpad `apply_inject_deploy.py`(COST·STOCK_COST 편집 적용·_T2 배포) + `dt_run_compare_T2.py`(dt 리다이렉트 실행→값불변 CHECKSUM·채움). 운영 배포 시 라이브 정의에 위 11건 재적용 후 ALTER, 당월 재결산(수치 동일·도우코드 채움) 대사.
