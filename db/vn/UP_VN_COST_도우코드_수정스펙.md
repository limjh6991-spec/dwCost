# UP_VN_COST 도우코드 수정 스펙 (수작업 반영용) — 260731

**전제(완료됨)**
- `V_VN_WIP_CONV` 컬럼명 **`wc_model` → `wc_code`** 변경됨 + 값=도우코드(716AP) ✓  (아래 EOHEQ 조인은 `v.wc_code` 사용)
- `doi_mat_cost` / `doi_expen_matl` 에 `도우코드` 컬럼 존재 + 값 채워짐 ✓ (model/도우모델 = 도우모델, 도우코드 = 도우코드)
- `DOI_COST` 에 `도우코드` 컬럼 추가됨(NOT NULL DEFAULT '') ✓

**원칙**: 집계·조인 키를 도우모델→도우코드로. MODEL 컬럼값은 도우모델 유지, 새 도우코드 컬럼 채움. (라인번호는 현재 정의 기준, 텍스트로 찾아 바꾸세요)

---

## A. 경비 브랜치 (`from doi_expen_matl`, L125~169)

**A-1. innermost SELECT 에 도우코드 추가** — `model,`(L138) 아래 한 줄 추가
```
         model,
         도우코드,          -- ← 추가 (doi_expen_matl.도우코드)
         expen_sel명,
```

**A-2. 윈도우 partition (L129~131)** — `구분,model` → `구분,도우코드` (3곳)
```
   변경전: over(partition by 구분,model)          (L129, L130)
   변경후: over(partition by 구분,도우코드)
   변경전: over(partition by 구분,model order by Ori_eoh DESC)   (L131)
   변경후: over(partition by 구분,도우코드 order by Ori_eoh DESC)
```

**A-3. EOHEQ 조인 (L156, L158)** — `v.wc_model = model` → `v.wc_code = doi_expen_matl.도우코드` (2곳) ※뷰 컬럼명 wc_code로 바뀜
```
   변경전: AND v.wc_model = model), 0)
   변경후: AND v.wc_code = doi_expen_matl.도우코드), 0)
```

**A-4. 기타입고 조인 (L160, L161)** — `p.도우모델=doi_expen_matl.model` → `p.도우코드=doi_expen_matl.도우코드` (2곳)
```
   변경전: AND p.도우모델=doi_expen_matl.model)
   변경후: AND p.도우코드=doi_expen_matl.도우코드)
```

---

## B. 재료비 브랜치 (`from doi_mat_cost`, L171~232)

**B-1. innermost SELECT 에 도우코드 추가** — `도우모델,`(L183) 아래 한 줄 추가
```
         도우모델,
         도우코드,          -- ← 추가 (doi_mat_cost.도우코드)
```

**B-2. 윈도우 partition (L174~176)** — `구분,도우모델` → `구분,도우코드` (3곳)

**B-3. EOHEQ 조인 (L219, L221)** — `v.wc_model = 도우모델` → `v.wc_code = doi_mat_cost.도우코드` (2곳) ※뷰 컬럼명 wc_code
```
   변경전: AND v.wc_model = 도우모델), 0)
   변경후: AND v.wc_code = doi_mat_cost.도우코드), 0)
```

**B-4. 기타입고 조인 (L223, L224)** — `p.도우모델=doi_mat_cost.도우모델` → `p.도우코드=doi_mat_cost.도우코드` (2곳)

---

## C. INSERT + 외부 SELECT (DOI_COST.도우코드 채우기, L84~90)

**C-1. INSERT 컬럼목록 (L85)** — `model ,` 다음에 `도우코드 ,` 추가
```
   변경전: ...SITE ,구분 ,model ,expen_sel명 ,ACCT_NAME...
   변경후: ...SITE ,구분 ,model ,도우코드 ,expen_sel명 ,ACCT_NAME...
```

**C-2. 외부 SELECT (L90)** — `model,` 다음에 `도우코드,` 추가
```
         구분,
         model,
         도우코드,          -- ← 추가 (a.도우코드, 양 브랜치가 동일 위치에 도우코드 생성하므로 OK)
         expen_sel명,
```

> ※ A-1·B-1 로 양 브랜치(UNION) 동일 위치에 도우코드가 생기므로 C-2 가 성립합니다.

---

## D. 재공평가 pq/uc 블록 (L582~608)

**D-1. uc (L582, L585)** — `MODEL` → `도우코드`
```
   변경전: SELECT SITE, 구분, MODEL, SUM(UNIT_COST) AS unit_cost_tot
   변경후: SELECT SITE, 구분, 도우코드, SUM(UNIT_COST) AS unit_cost_tot
   변경전: GROUP BY SITE, 구분, MODEL
   변경후: GROUP BY SITE, 구분, 도우코드
```

**D-2. pq (L588, L594)** — `도우모델` → `도우코드`
```
   변경전: SELECT SITE, 구분, 도우모델,   /   GROUP BY SITE, 구분, 도우모델
   변경후: SELECT SITE, 구분, 도우코드,   /   GROUP BY SITE, 구분, 도우코드
```

**D-3. ranked partition (L597~598)** — `c.MODEL` → `c.도우코드`
```
   변경전: ROW_NUMBER() OVER (PARTITION BY c.SITE, c.구분, c.MODEL ORDER BY c.[IN] DESC, c.ITEM_NAME)
   변경후: ROW_NUMBER() OVER (PARTITION BY c.SITE, c.구분, c.도우코드 ORDER BY c.[IN] DESC, c.ITEM_NAME)
```
   (ranked 의 SELECT 도 c.도우코드 를 뽑도록: `SELECT c.PL전_AMT, ..., c.MODEL, c.도우코드, ...` 에 c.도우코드 포함 필요)

**D-4. UPDATE 조인 (L607~608)** — MODEL 매칭 → 도우코드 매칭
```
   변경전: JOIN uc ON uc.SITE=r.SITE AND uc.구분=r.구분 AND uc.MODEL=r.MODEL
   변경후: JOIN uc ON uc.SITE=r.SITE AND uc.구분=r.구분 AND uc.도우코드=r.도우코드
   변경전: LEFT JOIN pq ON pq.SITE=r.SITE AND pq.구분=r.구분 AND pq.도우모델=r.MODEL
   변경후: LEFT JOIN pq ON pq.SITE=r.SITE AND pq.구분=r.구분 AND pq.도우코드=r.도우코드
```

---

## 검증 (반영 후)
1. `EXEC UP_VN_COST '202606','VN','ACTUAL'` 오류 없이 완료
2. `SELECT DISTINCT MODEL,도우코드 FROM DOI_COST WHERE yyyymm='202606' AND site='VN' AND MODEL LIKE '716A%'` → MODEL=716A, 도우코드=716AP
3. 716AP 재공평가(재료비): unit_cost_tot × EOHEQ ≈ 141,398 (도우모델 716A로는 EOHEQ 조인 실패해 0이던 게 정상화)
4. DOI_COST 총액(BOH/IN/EOH) 반영 전후 대사 — 누락 없는지
5. 다대일 818A: MODEL=818A 에 도우코드 818AD/818AP 로 분리되는지
