# VN 화면의 DOI_PROD_SUBUL / DOI_STOCK 참조 현황

> 작성일: 2026-08-04 · 대상 DB: **DWCMSTEST**(VN)
> 목적: VN 컨텍스트에서 base 테이블(`DOI_PROD_SUBUL`, `DOI_STOCK`)을 아직 참조하는 화면/프로시저를 식별해
> `DOI_VN_*_RESC` 계열로의 이관 대상을 정리한다.
> 근거: 라이브 `sys.sql_modules` 정의(단어경계 매칭) + 매퍼 XML 바인딩.

---

## 1. 리포트 화면 — VN 조회 시에도 base 테이블 참조 (미이관)

| 화면 / 탭 | queryId | 호출 프로시저 | 참조 테이블 | 비고 |
|---|---|---|---|---|
| 생산실적 > 년간 전체 실적 집계 (C0009001 TAB090003) | `C0009001_Tab090003` | `DOI_ManufacturingQtyByMonth` | **DOI_PROD_SUBUL** | VN 분기 없음(공용 프로시저) |
| 재공,제품원가 > 제조원가(재공) (C0009007 TAB090006) | `C0009007_Tab090006`, `..._Detail` | `DOI_ManufacturingCostOfWIP` | **DOI_PROD_SUBUL** | 공용/HQ 계보. VN 대체본=TAB090017 |
| 생산수불 (C0008000) | `C0008009_Sch1` | 인라인 SQL (`from doi_stock a`) | **DOI_STOCK** | |
| 타시스템 > 제품정보 (C0007004) | 적재/조회 | 인라인 SQL (`INSERT/UPDATE/SELECT DOI_STOCK`) | **DOI_STOCK** | 제품수불 원천 적재 |
| 타시스템 > 수불체크(생산/입고/판매) (C0007006) | 체크 조회 | 인라인 SQL | **DOI_STOCK** | |

---

## 2. 결산 실행 화면 — 실행 프로시저가 두 테이블을 읽음

**화면: VN 원가결산 실행 (C0003000 / VnProcRunner)** — 매퍼 `c0003000/C0003000.xml`

| 참조 테이블 | 프로시저 |
|---|---|
| **DOI_PROD_SUBUL** | `UP_VN_COST`, `UP_VN_EXPEN_MATL`, `UP_VN_MAT_COST`, `UP_VN_WIP_EVAL`, `UP_VN_COST_BOH`, `UP_VN_COST_UNIT`, `UP_VN_ACCT_EXPEN`, `UP_VN_EXPN_INPUT`, `ADJ_DOI_PROD_SUBUL` · (뷰) `V_VN_WIP_CONV`, `V_VN_PROCESS_RATE` |
| **DOI_STOCK** | `UP_VN_STOCK_BOH`, `UP_VN_STOCK_COST`, `ADJ_DOI_PROD_SUBUL` |

> 결산 프로시저는 화면 표시가 아니라 원가 계산의 입력으로 base 테이블을 사용한다.
> 화면 리포트 이관과 별개로, 결산 로직 자체의 소스 전환은 업무 확정 후 진행 대상.

---

## 3. (참고) 이미 이관 완료된 VN 화면 — base 테이블 미참조

| 화면 | 현재 소스 |
|---|---|
| 생산실적 > 월별 생산수불 (C0009001 TAB090001, `site='VN'` 분기) | `VN_ProdSubulMonthlyReport` |
| 생산실적 > 월별 집계(수량_VN) (C0009001 TAB090015) | `DOI_VN_PROD_RESC` (via `VN_ProductSubulMonthly`) |
| 재공,제품원가 > 제조원가(재공)_VN (C0009007 TAB090017) | `doi_vn_cost` (via `VN_WipCostLedger_Subul`) |
| 재공,제품원가 > 매출원가(제품)_VN (C0009007 TAB090016) | `DOI_VN_STCO` (via `VN_ProductCostLedger_Subul`) |
| 제품 수불부 VN탭 (C0009002) | `DOI_VN_STOCK_RESC` (via `VN_StockLedger_Detail`) |

---

## 4. 요약 / 이관 관점

- **VN 전용 신규 리포트**(TAB090015/016/017, 제품수불부 VN, TAB090001 VN분기)는 전부
  `DOI_VN_PROD_RESC` / `DOI_VN_STCO` / `doi_vn_cost` / `DOI_VN_STOCK_RESC`로 **이관 완료**.
- **아직 base 테이블을 보는 화면**:
  1. 공용/HQ 계보 탭 — `TAB090003`(년간 전체 실적), `TAB090006`(제조원가(재공))
  2. `DOI_STOCK` 직접 사용 화면 — `C0007004`(제품정보), `C0007006`(수불체크), `C0008000`(생산수불)
  3. 결산 실행(`C0003000`)의 `UP_VN_*` / `ADJ_DOI_PROD_SUBUL` 프로시저

### 참조 체인(예시)
```
[화면] C0009001 TAB090003 (년간 전체 실적 집계)
   └─ EXEC DOI_ManufacturingQtyByMonth
         └─ FROM DOI_PROD_SUBUL

[화면] C0009007 TAB090006 (제조원가(재공))
   └─ EXEC DOI_ManufacturingCostOfWIP
         └─ FROM DOI_PROD_SUBUL

[화면] C0008000 생산수불 (C0008009_Sch1)
   └─ 인라인 SQL: from doi_stock a
```

### 재현 방법(감사 쿼리)
```sql
-- DOI_PROD_SUBUL 정확 참조 객체
SELECT o.name, o.type_desc
FROM sys.sql_modules m JOIN sys.objects o ON o.object_id = m.object_id
WHERE PATINDEX('%DOI[_]PROD[_]SUBUL[^_0-9A-Za-z]%', m.definition + ' ') > 0
ORDER BY o.type_desc, o.name;

-- DOI_STOCK 정확 참조 객체 (DOI_STOCK_BOH 등 동시참조 포함)
SELECT o.name, o.type_desc
FROM sys.sql_modules m JOIN sys.objects o ON o.object_id = m.object_id
WHERE PATINDEX('%DOI[_]STOCK[^_0-9A-Za-z]%', m.definition + ' ') > 0
ORDER BY o.type_desc, o.name;
```
> 매퍼 인라인 SQL(C0007004/C0007006/C0008000)은 DB 객체가 아니므로 위 쿼리에 안 잡힌다.
> `src/main/resources/mapper/**/*.xml`에서 `DOI_STOCK` 문자열로 별도 확인.
