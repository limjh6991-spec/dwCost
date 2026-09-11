# 202608 재고원가 결함 A·B 수정 (제품재고 RMA 평가 + 공정재투입 금액)

작성 2026-09-11 / 대상 DB: 도우제조원가시스템 (10.100.40.17,14233)
배포 파일: **`UP_DOI_STOCK_COST_fix260911.sql`** (백업 `_bak260911.sql`)

---

## 배경

`UP_DOI_STOCK_COST`는 제품재고 수불금액(DOI_STCO)을 산출한다(L99 `DELETE FROM DOI_STCO` 후 재생성).
담당자 특이사항 검증에서 두 결함이 실측 확정됐다.

> **구조 메모**: 결산 순서는 `UP_DOI_STOCK_BOH`(Sch1) → `UP_DOI_STOCK_COST`(Sch2)이고,
> STOCK_COST가 DOI_STCO를 통째로 재생성한다. 따라서 STOCK_BOH STEP6(L742~972)의
> RMA 후처리는 **직후 덮어써져 무효**다(죽은 코드). 그래서 모든 수정을 STOCK_COST에서 한다.
> STEP6가 하려던 **양산측 반품 크레딧(C)**은 원래부터 미반영이던 선행 결함으로, 담당자 확인 후
> 별건 처리한다(이 문서 범위 밖).

## 결함

### (B) RMA 반품입고 금액이 stale 단가

`RMA_IN_AMT = ROUND(a.RMA_IN_QTY × COALESCE(ru.RMA_UNITCOST, 0), 0)` (L377).
`ru`(STUC_RMA_LATEST, L259~290)는 `DOI_STUC`의 전월 이하 `EXPEN_SEL='RMA1'` 최신 단가인데,
RMA 재고가 202601 이후 안 움직여 **202601 단가에 고정**되어 있다.
→ 실측 RMA_IN_AMT 합 **64,477,941** (담당자 반품리스트 **95,257,838** 대비 −30.8M 과소).

`ru.RMA_UNITCOST × RMA_IN_QTY`는 RMA_IN_AMT뿐 아니라 폐기/연구/기타 단가 분자(L385/388/391),
기말평가 분자(L403~406), 출고단가 OUT_UNIT_AMT(L414)에도 쓰여 **전 산식이 과소평가**된다.

### (A) 공정재투입(제품→재공 R/W) 출고금액이 리터럴 0

`0 AS OUT_REWORK_AMT` (L327). 공정재투입 수량 OUT_REWORK_QTY(L212, 7073R=258)는 집계되나
금액이 0이고, OUTETC_AMT 합산(L324)·OUT_AMT 잔차(L492)에도 미반영.
→ 7073R의 258개 8,146,083이 제품재고에서 빠지지 않아 재공 입고와 대사가 깨진다.

---

## 수정 — 두 결함이 연결되어 있다

**핵심**: (B)로 RMA 평가를 `DOI_STOCK.RMA_AMT`로 바로잡으면 출고단가 OUT_UNIT_AMT가 정확해지고,
그 단가로 (A) OUT_REWORK_AMT가 자동으로 담당자값이 된다.

| 결함 | 줄(원문) | 변경 |
|---|---|---|
| B | L218 뒤 | `MODEL_STOCK`에 `SUM(ISNULL(a.RMA_AMT,0)) AS RMA_AMT` 추가 |
| B | L377 | `ROUND(a.RMA_IN_QTY × COALESCE(ru.RMA_UNITCOST,0),0)` → `COALESCE(a.RMA_AMT,0)` |
| B | L385·388·391 | `COALESCE(ROUND(A.RMA_IN_QTY×…ru…),0)` → `COALESCE(A.RMA_AMT,0)` (폐기/연구/기타 단가 분자) |
| B | L403·404·405·406 | 동 (Ori/Base_EOH_AMT 분자) |
| B | L414 | 동 (OUT_UNIT_AMT 분자) |
| A | L327 | `0 AS OUT_REWORK_AMT` → `ROUND(OUT_REWORK_QTY × OUT_UNIT_AMT,0)` |
| A | L324 | OUTETC_AMT 합산에 `+ coalesce(ROUND(OUT_REWORK_QTY×OUT_UNIT_AMT,0),0)` |
| A | L492 | OUT_AMT 잔차식에 `- OUT_REWORK_AMT` |

`ru`(STUC_RMA_LATEST) CTE와 그 LEFT JOIN(L446~450)은 사용처가 없어지지만 무해하게 남겨둔다.
646 → 647줄. UTF-8(BOM 없음).

---

## 검증 — 실제 프로시저 공식으로 8모델 전수 재현 (읽기전용)

`OUT_UNIT_AMT = (BOH_AMT + IN_AMT + INETC_AMT + RMA_AMT) / (BOH + INPUT + INETC)` 을
실제 `MODEL_STOCK`(DOI_STOCK) + `MODEL_BOH_AMT`(DOI_STOCK_BOH) 원천값으로 재현:

```
모델   BOH_AMT       INETC_AMT  RMA_AMT       denom  EOH단가     EOH_AMT       OUT_REWORK
7073   6,821,974     0          3,565,861     329    31,573.97   2,241,752     8,146,083   ← 담당자 완전일치
7110   0             0          1,006,207     97     10,373.27   1,006,207     0
8085   0             0          54,984        10     5,498.40    54,984        0
810P   0             0          4,685,636     58     80,786.83   4,685,636     0
8122   103,247,685   0          5,417,098     693    156,803.44  108,664,783   0
8136   71,601,627    0          8,189,758     8248   9,674.03     79,791,385    0
8140   0             0          9,100         2      4,550.00    9,100         0
902K   1,592,565     0          72,329,194    963    76,761.95   73,921,759    0
       합계 RMA_AMT 95,257,838 (담당자 일치) / EOH_AMT 270,375,606 / OUT_REWORK 8,146,083
```

- **INETC_AMT가 8모델 전부 0** → RMA_AMT 이중계상 없음(단가 정확).
- **7073R**: 기초 6,821,974 + 입고 3,565,861 = 출고 8,146,083 + 기말 2,241,752 (담당자 재고수불부 완전 일치).
  OUT_REWORK 8,146,083 = 재공 DOI_COST RMA1 eoh 8,146,083 (출고=입고 대사 성립).
- **8개 모델 전수 항등식 성립, 음수 없음**(902K 72.3M 반품 포함).
- **8136 R행 2개(완제품 8,189,758 / 현장 0)**: `MODEL_STOCK`이 model+구분 GROUP 이라
  `SUM(RMA_AMT)=8,189,758`로 자동 합산 → 비결정성(결함 D) 없이 해결.

ALTER 롤백 테스트 컴파일 통과(OUT_UNIT_AMT 스코프 유효). 운영 EXEC는 정책상 미실행.

---

## 영향

- 제품재고 EOH_AMT **+29.4M** 증가(902K +58.6M 주도, 8122·8136 stale값 정정으로 상쇄).
  → 기말 제품재고자산 평가액 상향. **재무제표/매출원가 영향이므로 담당자 리뷰 권장.**
- 회귀 낮음: 202606/202607 HQ는 RMA 활동 0건이라 재실행해도 불변. 202608에서 값이 바뀌는 건
  RMA_AMT≠0 8개 R행(B)과 공정재투입≠0 인 7073R 1건(A)뿐. 양산 P행·비RMA·카세트(VN034)는 불변.

## 적용 절차 (SSMS/DBeaver)

```
1) UP_DOI_STOCK_COST_fix260911.sql   실행
2) 결산 재실행: UP_DOI_STOCK_BOH → UP_DOI_STOCK_COST → UP_DOI_SALE_COST → UP_DOI_SCOF
   (STOCK_COST 부터 다시 돌리면 됨. 앞단 제조원가/재공은 불변)
```

## 적용 후 대사

```sql
-- (a) RMA 반품입고 총액 = 95,257,838
SELECT SUM(RMA_IN_AMT) FROM DOI_STCO WHERE YYYYMM='202608' AND SITE='HQ' AND 구분='RMA';
-- (b) 7073R 담당자 대사
SELECT MODEL, BOH_AMT, RMA_IN_AMT, EOH_AMT, OUT_REWORK_AMT, OUT_AMT
  FROM DOI_STCO WHERE YYYYMM='202608' AND SITE='HQ' AND 구분='RMA' AND MODEL='7073';
-- BOH 6,821,974 / RMA_IN 3,565,861 / EOH 2,241,752 / OUT_REWORK 8,146,083 / OUT 0
-- (c) 출고=입고 대사
SELECT (SELECT OUT_REWORK_AMT FROM DOI_STCO WHERE YYYYMM='202608' AND SITE='HQ' AND 구분='RMA' AND MODEL='7073') AS 제품출고,
       (SELECT eoh FROM DOI_COST WHERE YYYYMM='202608' AND SITE='HQ' AND EXPEN_SEL='RMA1') AS 재공입고;
-- 둘 다 8,146,083
```

## 남은 것 (별건)

- **(C) 양산측 반품 크레딧**: STEP6가 하려던 `양산 OUTETC_AMT = DOI_STOCK.RMA_AMT`가 STOCK_COST
  재생성으로 소실 → 원래부터 미반영. "P모델 반품 크레딧을 매출원가에서 어떻게 차감할지" 담당자 확인 후
  STOCK_COST에 신규 반영 필요. (이 문서 A·B와 독립)
