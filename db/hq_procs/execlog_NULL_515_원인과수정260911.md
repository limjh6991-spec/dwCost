# 202608 결산 1단계 `SQL Error [515]` — 원인과 수정

작성 2026-09-11 / 대상 DB: 도우제조원가시스템 (10.100.40.17,14233)

---

## 증상

202608 HQ 결산을 처음부터(1단계 `UP_DOI_EXPEN_MATL`) 실행하면:

```
SQL Error [515] [23000]: 테이블 '도우제조원가시스템.dbo.doi_execlog',
열 'rslt_message'에 NULL 값을 삽입할 수 없습니다. 열에는 NULL을 사용할 수 없습니다.
INSERT이(가) 실패했습니다.
```

`doi_execlog` 에 202608 기록이 **0건** (최신 HQ 기록은 2026-08-23). 산출물도 전부 0행.

---

## 근본 원인 — `EXPEN_SEL명 = 'RMA_RW'` 는 ASCII 6자

`UP_DOI_EXPEN_MATL` **STEP 9 (RMA 재투입)** L683~L750 이 `DOI_EXPEN_MATL` 에
아래 리터럴로 INSERT 한다.

```sql
'RMA1'   AS EXPEN_SEL,
'RMA_RW' AS EXPEN_SEL명,
```

STEP 10 검증부의 항목별 커서(L837)는 `DOI_EXPEN_MATL` 을 **계정 필터 없이** 훑으므로
이 `RMA1 / RMA_RW` 행을 그대로 집어온다. 그리고 L896:

```sql
+ LEFT(ISNULL(@EXPEN_NAME, '') + REPLICATE(' ', 3-dbo.DOI_ASCII_COUNT(@EXPEN_NAME))
       + REPLICATE(NCHAR(0x3000), 15), 17)
```

`dbo.DOI_ASCII_COUNT('RMA_RW')` = **6** → `REPLICATE(' ', 3-6)` = `REPLICATE(' ', -3)` = **NULL**.

SQL Server 에서 `문자열 + NULL = NULL` 이므로 이 줄에서 `@Message` 가 통째로 NULL 이 되고,
이후 L897~L946 의 모든 연결도 NULL 을 유지한 채 L952 의 execlog INSERT 에 도달한다.
`rslt_message` 는 `nvarchar(max) NOT NULL` → **515**.

### 왜 로그가 한 줄도 안 남았나 — CATCH 가 같은 NULL 을 재사용

```sql
L969  BEGIN CATCH
L973      SET @Message = @Message + char(10) + '[ERROR] ' + ... + ERROR_MESSAGE();   -- NULL + x = NULL
L974      INSERT INTO doi_execlog (... rslt_message ...) values (..., @Message, ..., 'FAIL');
```

CATCH 는 NULL 인 `@Message` 에 문자열을 덧붙일 뿐이라 여전히 NULL → **CATCH 의 INSERT 도 515**.
그래서 원래 에러가 가려지고 로그가 남지 않는다. 관측된 "202608 0건" 과 정확히 일치한다.

### 왜 하필 202608 인가 — RMA 최초 발생월

| 검증 | 결과 |
|---|---|
| `DOI_PROD_SUBUL` 에 `기타입고_RMA_RW <> 0` 이 있는 월 | **202608 뿐** (1행 / 258개 / 모델 1종) |
| 전 기간 `DOI_EXPEN_MATL` 의 `EXPEN_SEL='RMA1'` | **0건** |
| 202607 `DOI_EXPEN_MATL` 의 최대 ASCII 수 | 3 (통과) |

즉 STEP 9 가 실제로 행을 만든 것이 이번이 처음이고, 그래서 커서가 `RMA_RW` 를 처음 만났다.

### 같은 사고의 전례

`UP_DOI_COST` 는 **이미** 같은 자리를 방어하고 있다 — 과거에 한 번 겪고 고친 흔적이다.

```sql
UP_DOI_COST L796 : + LEFT(ISNULL(@EXPEN_NAME,'') + ISNULL(REPLICATE(' ',3-dbo.DOI_ASCII_COUNT(@EXPEN_NAME)),'') + ...
UP_DOI_COST L956 : (@EXPEN_NAME_DTL 에 대해 동일)
UP_DOI_COST L1120/L1152 : rslt_message 자리에 ISNULL(@Message,'[로그 생성 경고]')
```

이번 수정은 그 형태를 그대로 따른다.

---

## 2차 블로커 — `UP_DOI_FAB_COST` (경비집계 바로 다음 단계)

`UP_DOI_EXPEN_MATL` 만 고치면 다음 단계에서 **같은 에러가 다시 난다.**

1. `UP_DOI_FAB_COST` L402~L407 커서도 `DOI_EXPEN_MATL` 을 훑어 `RMA1 / RMA_RW` 를 가져오고,
   L438 이 동일한 무방비 `REPLICATE(' ',3-DOI_ASCII_COUNT(...))` 를 쓴다. L358 도 같다.
2. 별개로 L267 / L276 의 집계가 **0행이면 NULL** 이다.

```sql
L267 select @VN_CASSTE_AMT = sum(a.ACCT_AMT * c.VINA_CST * coalesce(d.rate,0)), @VN_CASSTE_CNT = count(*)
L276 select @CASSTE_AMT    = sum(a.ACCT_AMT * c.UTG      * coalesce(d.rate,0)), @CASSTE_CNT    = count(*)
```

`coalesce(d.rate,0)` 는 `d.rate` 만 막고 `sum()` 자체는 막지 않는다.
`DOI_ACCT_EXPEN` 202608 이 0행인 상태(= EXPEN_MATL 실패로 롤백된 상태)에서 실측하면:

```
202607 : VN_AMT=35,532,623.32  CNT=75  UTG_AMT=72,044,195.68
202608 : VN_AMT=★NULL          CNT=0   UTG_AMT=★NULL
```

→ L306/L307 의 `FORMAT(@VN_CASSTE_AMT,'N0')` 가 NULL → `@Message` NULL → 같은 515.

그래서 두 프로시저를 **함께** 수정한다.

---

## 수정 내용

라이브 정의(`OBJECT_DEFINITION`)를 받아 그 위에서만 수정했다. 저장소본은 배포하지 않았다.

### `UP_DOI_EXPEN_MATL_fix260911b.sql` — 989줄, 차이 3줄(+ CREATE→ALTER)

| 줄 | 변경 |
|---|---|
| L896 | `REPLICATE(' ', 3-DOI_ASCII_COUNT(@EXPEN_NAME))` → `ISNULL(REPLICATE(...),'')` |
| L955 | execlog SUCCESS 의 `@Message` → `ISNULL(@Message, '[로그 생성 경고]')` |
| L977 | execlog FAIL 의 `@Message` → `ISNULL(@Message, '[로그 생성 경고]')` |

### `UP_DOI_FAB_COST_fix260911b.sql` — 511줄, 차이 6줄(+ CREATE→ALTER)

| 줄 | 변경 |
|---|---|
| L267 | `sum(...)` → `ISNULL(sum(...),0)` (@VN_CASSTE_AMT) |
| L276 | `sum(...)` → `ISNULL(sum(...),0)` (@CASSTE_AMT) |
| L358 | `REPLICATE(' ',3-DOI_ASCII_COUNT(@EXPEN_NAME))` → `ISNULL(REPLICATE(...),'')` |
| L438 | `REPLICATE(' ',3-DOI_ASCII_COUNT(@EXPEN_NAME_DTL))` → `ISNULL(REPLICATE(...),'')` |
| L491 | execlog SUCCESS 의 `@Message` → `ISNULL(@Message, '[로그 생성 경고]')` |
| L504 | execlog FAIL 의 `@Message` → `ISNULL(@Message, '[로그 생성 경고]')` |

execlog 가드는 증상 은폐가 아니라 **진단 가능성 복구**다. 이게 있었다면 이번 에러도
`rslt_message='[로그 생성 경고]'` 로 FAIL 이 남아 원인이 바로 보였을 것이다.
근본 원인(L896 등)은 별도로 고쳤다.

### 백업

```
UP_DOI_EXPEN_MATL_bak260911b.sql   (수정 전 라이브, 2026-08-13 20:02:16 판)
UP_DOI_FAB_COST_bak260911b.sql     (수정 전 라이브, 2026-03-25 15:59:16 판)
```

---

## 적용 절차 (SSMS)

```
1) UP_DOI_EXPEN_MATL_fix260911b.sql   실행   ← 배포 완료 (2026-09-11 11:11:26)
2) UP_DOI_FAB_COST_fix260911b.sql     실행   ← ★미배포
3) 202608 HQ 결산 처음부터 재실행
```

> **[2026-09-11 갱신]** 1번은 배포되었다(라이브 989줄, L896/L955/L977 가드 확인).
> 이후 RMA 재투입 금액 반영(B안)이 확정되어 **`UP_DOI_EXPEN_MATL_fix260911c.sql`** 이
> 이 파일의 내용을 포함한 상위 버전이 되었다. 1번을 다시 실행할 필요는 없고,
> 앞으로는 c 를 배포하면 된다. 상세: `RMA_재투입금액_B안_260911.md`
> 2번(`UP_DOI_FAB_COST`)은 여전히 2026-03-25 판이라 반드시 배포해야 한다.

### 적용 후 대사

```sql
-- (a) 가드가 살아있는지
SELECT CASE WHEN OBJECT_DEFINITION(OBJECT_ID('UP_DOI_EXPEN_MATL'))
              LIKE '%ISNULL(REPLICATE('' '', 3-dbo.DOI_ASCII_COUNT(@EXPEN_NAME)),'''')%'
            THEN 'OK' ELSE 'NG' END AS EXPEN_MATL_가드;

-- (b) 실행 로그가 남는지 (이전엔 0건이었다)
SELECT proc_name, exec_rslt, exec_date, LEFT(rslt_message,80) AS msg
  FROM doi_execlog WHERE yyyymm='202608' AND site='HQ' ORDER BY exec_date;

-- (c) STEP9 RMA 행이 들어갔는지
SELECT MODEL, SUB_NAME, EXPEN_SEL, EXPEN_SEL명, ETC_IN_RMA_QTY, unit_cost, [in], boh
  FROM DOI_EXPEN_MATL
 WHERE YYYYMM='202608' AND SITE='HQ' AND EXPEN_SEL='RMA1';
-- 1행(모델 7073), ETC_IN_RMA_QTY=258 이어야 한다

-- (d) 소스 vs 타겟
SELECT (SELECT ISNULL(SUM(CAST(ACCT_AMT AS BIGINT)),0) FROM DOI_ACCT_EXPEN
         WHERE yyyymm='202608' AND site='HQ' AND sel_code='ACTUAL'
           AND ACCT LIKE '5%' AND ACCT NOT LIKE '51%')          AS 소스,
       (SELECT ISNULL(CAST(SUM([IN]) AS BIGINT),0) FROM DOI_EXPEN_MATL
         WHERE YYYYMM='202608' AND SITE='HQ' AND sel_code='ACTUAL') AS 타겟;
```

---

## 함께 확인이 필요한 점 (이번 수정 범위 밖)

### 1. STEP 9 의 RMA 단가 원천이 하드코딩 월이고 데이터가 없다

```sql
L656  FROM DOI_STCO s
L657  WHERE s.YYYYMM = '202512'      -- ← 하드코딩
L660    AND s.구분 = 'RMA'
```

`DOI_STCO 202512 / HQ / 구분='RMA'` 는 **0행**이다. 따라서 `u.RMA_UNIT_COST` 가 없고
`ISNULL(u.RMA_UNIT_COST, 0)` 에 의해 **`unit_cost = 0`** 으로 INSERT 된다.
STEP 9 는 `boh`/`[in]` 을 리터럴 0 으로 넣으므로 **경비 금액에는 영향이 없고 수량만 기록**되지만,
RMA 재투입 단가를 쓰려는 의도였다면 `'202512'` 를 `@PREV_MONTH` 로 바꾸는 등의 결정이 필요하다.
원 설계 의도 확인 후 별도 처리 권장.

### 2. 같은 RMA 258개가 재료비 쪽에도 잡혀 있다 (교차 확인됨)

- `DOI_PROD_SUBUL` 202608 `기타입고_RMA_RW` = 258 (도우코드 7073*)
- `DOI_MATL_RESC` 202608 자재번호 7073R / 투입수량 258 / 투입금액 8,146,083 / 품목자산분류 `제품`

`UP_DOI_MAT_AMT` 의 `품목자산분류 <> N'제품'` 제외(9곳, 라이브 반영 완료)가 바로 이 건이다.
두 경로가 같은 물량을 가리키므로 제외 판단이 맞다는 교차 근거가 된다.

### 3. `UP_DOI_MAT_AMT` 배포 상태 (정정)

라이브 `UP_DOI_MAT_AMT` (modify_date 2026-09-11 10:52:39) 는 **9곳 모두 반영**되어 있다.
repo 의 `UP_DOI_MAT_AMT_fix260911.sql` 과 라이브의 차이는 `CREATE`/`ALTER` 한 줄과
L204 공백뿐이다. 재배포 불필요.

### 4. 남아 있는 동종 위험

`doi_execlog` 에 쓰는 HQ 프로시저 중 `rslt_message` 자리에 아직 맨 `@Message` 를 넘기는 것:
`UP_DOI_MAT_AMT`, `UP_DOI_MAT_COST`, `UP_DOI_STOCK_BOH`, `UP_DOI_SALE_COST`, `UP_DOI_SCOF`.
정적 분석상 현재 이들에는 NULL 경로가 없지만(변수 전부 초기화 + `ISNULL` 대입),
같은 사고의 재발 방지를 위해 일괄 `ISNULL(@Message, ...)` 적용을 별도 건으로 검토 권장.
