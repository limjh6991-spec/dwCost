# UP_DOI_STOCK_COST 프로시저 변경사항

> **변경일:** 2025년 11월 10일  
> **변경 사유:** expen_sel (원가항목) 필드 추가로 원가 세분화  
> **관련 프로시저:** UP_DOI_STOCK_BOH (선행 변경 완료)

---

## 📋 변경 개요

UP_DOI_STOCK_COST 프로시저를 **expen_sel (원가항목)** 기준으로 집계하도록 수정하여, 재료비/가공비/노무비 등 원가항목별로 제품 수불 금액을 상세하게 추적할 수 있도록 개선하였습니다.

---

## ⭐ 주요 변경 사항

### 1. **MODEL_IN_AMT CTE** (Line 96-101)
```sql
-- 변경 전
SELECT a.YYYYMM, a.site, a.model, a.구분, SUM([out]) IN_AMT
FROM DOI_FAB_COST a 
WHERE A.yyyymm=@YYYYMM AND a.site=@SITE
GROUP BY a.yyyymm, a.site, a.model, a.구분

-- 변경 후
SELECT a.YYYYMM, a.site, a.model, a.구분, a.expen_sel, SUM([out]) IN_AMT  -- ⭐ expen_sel 추가
FROM DOI_FAB_COST a 
WHERE A.yyyymm=@YYYYMM AND a.site=@SITE
GROUP BY a.yyyymm, a.site, a.model, a.구분, a.expen_sel  -- ⭐ GROUP BY에 추가
```

### 2. **MODEL_BOH_AMT CTE** (Line 102-107)
```sql
-- 변경 전
SELECT a.YYYYMM, a.site, a.model, a.구분, SUM(BOH_AMT) BOH_AMT
FROM DOI_STOCK_BOH a 
WHERE A.yyyymm=@YYYYMM AND a.site=@SITE
GROUP BY a.yyyymm, a.site, a.model, a.구분

-- 변경 후
SELECT a.YYYYMM, a.site, a.model, a.구분, a.expen_sel, SUM(BOH_AMT) BOH_AMT  -- ⭐ expen_sel 추가
FROM DOI_STOCK_BOH a 
WHERE A.yyyymm=@YYYYMM AND a.site=@SITE
GROUP BY a.yyyymm, a.site, a.model, a.구분, a.expen_sel  -- ⭐ GROUP BY에 추가
```

### 3. **MODEL_EOH_AMT CTE** (Line 131-150)
```sql
-- 변경 전
select
    a.YYYYMM, a.SITE, a.SEL_CODE, a.구분, A.MODEL,
    A.BOH, A.INPUT, A.OUT, A.EOH,
    B.BOH_AMT,
    coalesce(c.IN_AMT,0) as IN_AMT,
    round(...) as EOH_AMT
from MODEL_STOCK a
 left join MODEL_BOH_AMT b 
     on (a.yyyymm=b.yyyymm and a.site=b.site and a.model=b.model and b.구분=a.구분)
 left join MODEL_IN_AMT c  
     on (a.yyyymm=c.yyyymm and a.site=c.site and a.model=c.model and c.구분=a.구분)

-- 변경 후
select
    a.YYYYMM, a.SITE, a.SEL_CODE, a.구분, A.MODEL,
    b.expen_sel,  -- ⭐ expen_sel 추가
    A.BOH, A.INPUT, A.OUT, A.EOH,
    B.BOH_AMT,
    coalesce(c.IN_AMT,0) as IN_AMT,
    round(...) as EOH_AMT
from MODEL_STOCK a
 left join MODEL_BOH_AMT b 
     on (a.yyyymm=b.yyyymm and a.site=b.site and a.model=b.model and b.구분=a.구분)
 left join MODEL_IN_AMT c  
     on (a.yyyymm=c.yyyymm and a.site=c.site and a.model=c.model and c.구분=a.구분 
         and c.expen_sel=b.expen_sel)  -- ⭐ JOIN 조건에 expen_sel 추가
```

### 4. **INSERT 정렬 순서** (Line 155)
```sql
-- 변경 전
ORDER BY a.MODEL, a.구분;

-- 변경 후
ORDER BY a.MODEL, a.expen_sel, a.구분;  -- ⭐ expen_sel 정렬 추가
```

---

## 🎯 변경 효과

### 1. **원가항목별 세분화**
- DOI_STOCK_COST 테이블에 expen_sel 컬럼이 포함되어 저장
- 재료비, 가공비, 노무비 등을 구분하여 제품 수불 금액 추적 가능

### 2. **데이터 정합성 유지**
- DOI_FAB_COST (expen_sel 포함) → DOI_STOCK_BOH (expen_sel 포함) → DOI_STOCK_COST (expen_sel 포함)
- 전체 데이터 흐름에서 원가항목별 일관성 유지

### 3. **더 정교한 원가 분석**
- 원가 요소별 재고금액 변동 추적
- 원가항목별 BOH/IN/OUT/EOH 금액 분석 가능

---

## 📌 주의사항

### ⚠️ **테이블 구조 변경 필요**
DOI_STOCK_COST 테이블에 `expen_sel` 컬럼이 추가되어야 합니다:

```sql
ALTER TABLE DOI_STOCK_COST ADD expen_sel VARCHAR(20);
```

**사용자가 직접 수정 예정** (문서 요청사항 반영)

### ⚠️ **선행 조건**
1. **DOI_FAB_COST**: expen_sel 컬럼 필수
2. **DOI_STOCK_BOH**: expen_sel 컬럼 필수 (UP_DOI_STOCK_BOH에서 생성)
3. **DOI_STOCK_COST**: expen_sel 컬럼 추가 필요

### ⚠️ **기존 데이터 마이그레이션**
기존 DOI_STOCK_COST 데이터에 expen_sel 값이 NULL일 경우:
- 기본값 설정 또는
- 과거 데이터 재집계 고려

---

## 🔍 검증 방법

### 1. expen_sel 기준 집계 확인
```sql
SELECT 
    YYYYMM, SITE, MODEL, 구분, expen_sel,
    SUM(BOH_AMT) AS TOT_BOH_AMT,
    SUM(IN_AMT) AS TOT_IN_AMT,
    SUM(EOH_AMT) AS TOT_EOH_AMT,
    SUM(OUT_AMT) AS TOT_OUT_AMT
FROM DOI_STOCK_COST
WHERE YYYYMM = '202510' AND SITE = 'HQ'
GROUP BY YYYYMM, SITE, MODEL, 구분, expen_sel
ORDER BY MODEL, expen_sel;
```

### 2. 원가항목별 합계 검증
```sql
-- DOI_FAB_COST.[out] vs DOI_STOCK_COST.IN_AMT (원가항목별)
SELECT 
    f.expen_sel,
    SUM(f.[out]) AS FAB_OUT,
    s.IN_AMT AS STOCK_IN,
    ABS(SUM(f.[out]) - s.IN_AMT) AS DIFF
FROM DOI_FAB_COST f
LEFT JOIN DOI_STOCK_COST s 
    ON f.YYYYMM = s.YYYYMM 
   AND f.site = s.SITE 
   AND f.model = s.MODEL 
   AND f.구분 = s.구분
   AND f.expen_sel = s.expen_sel  -- ⭐ expen_sel 조인
WHERE f.YYYYMM = '202510' AND f.SITE = 'HQ'
GROUP BY f.expen_sel, s.IN_AMT
HAVING ABS(SUM(f.[out]) - s.IN_AMT) > 0.01;
-- 결과: 0건이어야 함
```

### 3. NULL 체크
```sql
SELECT COUNT(*) AS NULL_COUNT
FROM DOI_STOCK_COST
WHERE YYYYMM = '202510' AND SITE = 'HQ'
  AND expen_sel IS NULL;
-- 결과: 0건이어야 함
```

---

## 📂 관련 파일

| 파일 | 경로 | 상태 |
|------|------|------|
| 프로시저 | `/src/원가SQL/UP_DOI_STOCK_COST` | ✅ 수정 완료 |
| 백업 파일 | `/src/원가SQL/UP_DOI_STOCK_COST.backup` | ✅ 생성됨 |
| 분석 문서 | `/docs/C0003009_제품수불_로직분석.md` | ✅ v1.1 업데이트 완료 |
| 선행 프로시저 | `/src/원가SQL/UP_DOI_STOCK_BOH` | ✅ expen_sel 반영 완료 |

---

## 📝 실행 전 체크리스트

- [ ] DOI_STOCK_COST 테이블에 expen_sel 컬럼 추가
- [ ] DOI_FAB_COST에 expen_sel 데이터 존재 확인
- [ ] DOI_STOCK_BOH에 expen_sel 데이터 존재 확인 (UP_DOI_STOCK_BOH 실행 후)
- [ ] 테스트 환경에서 프로시저 실행 및 검증
- [ ] 검증 SQL 실행하여 데이터 정합성 확인
- [ ] 운영 배포 전 백업 수행

---

**작성자:** GitHub Copilot  
**검토자:** (담당자명)  
**승인자:** (책임자명)
