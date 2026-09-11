/* ============================================================================
   [수정방안] UP_DOI_COST — 카세트(VINA CST) 기초재공(BOH) 미반영 결함
   작성 2026-09-11 / 대상 DB: 도우제조원가시스템 (10.100.40.17,14233)
   ============================================================================

   ■ 원인
     UP_DOI_COST 의 카세트 전용 INSERT 블록(라이브 L458~L511)이 전월 재공을 읽지 않는다.
       · base CTE 가 doi_expen_matl.[IN] / doi_mat_cost.배부금액 만 읽고 boh / boh_amt 미참조
       · INSERT 컬럼목록에 BOH 가 없고 BOH_QTY 는 리터럴 0 하드코딩(L503)
       · 재공품단가 분모 DENOM = IN_QTY - LOSS_QTY (L485) 에 BOH_QTY 누락
     같은 프로시저의 일반(비카세트) 브랜치는 boh 를 정상 사용한다. 카세트 블록만 빠져 있다.

   ■ 왜 지금 터지는가
     202607 은 카세트 첫 달이라 BOH=0 이었다. 202608 이 기초재공을 갖는 최초의 달이다.
     동시에 202608 은 카세트가 처음 매출로 나가는 달(수출 인보이스 139,498,299)이라
     손익에 바로 영향이 간다.

   ■ 상류는 이미 BOH 를 만들어 둔다 (수정 불필요)
     UP_DOI_EXPEN_MATL STEP8 : UPDATE doi_expen_matl SET boh=0 후
       전월_EOH(DOI_COST WHERE yyyymm=전월 AND eoh<>0 AND expen_sel NOT IN ('MDAX','MIAX'))
       를 MERGE → t.BOH_QTY=s.EOH_QTY, t.BOH=s.EOH   ... 경비 28,890,713
     UP_DOI_MAT_COST       : UPDATE DOI_MAT_COST SET boh_amt=0 후
       전월_EOH(expen_sel IN ('MDAX','MIAX')) 를 MERGE → t.BOH_AMT=s.EOH  ... 재료비 20,922,276
     합계 49,812,989 = 202607 DOI_COST 카세트 EOH 와 정확히 일치
       (VN034P1 24,496,087 / VN034P2 19,460,992 / VN034P3 5,855,910)
     따라서 카세트 블록이 그 컬럼을 읽기만 하면 된다.

   ■ 변경점 5가지 (CTE 구조·largest-remainder·LOSS 규칙은 불변)
     (1) base   : BOH_ROW(b.BOH / m.BOH_AMT), BOH_QTY(ps.BOH_MONTH) 추가 + ISNULL 방어
     (2) calc   : POOL_ROW = BOH_ROW + IN_ROW
                  DENOM    = BOH_QTY + IN_QTY - LOSS_QTY   (BOH_QTY 가산)
                  IN_PROD  = SUM(POOL_ROW) OVER (PARTITION BY MODEL)
     (3) r1/r3  : EOH 안분 분자 IN_ROW -> POOL_ROW (정렬 타이브레이크도 동일)
     (4) INSERT : 컬럼목록에 BOH 추가, BOH_QTY 리터럴 0 -> BOH_QTY
     (5) [OUT]/LOSS/LOSS_DEFECT_AMT 의 IN_ROW -> POOL_ROW

   ■ 202608 적용 시 예상 (상류를 SELECT 로 1:1 재현해 산출, 추정치 아님)
     모델      BOH_QTY IN_QTY EOH_QTY OUT_QTY LOSS_QTY DENOM  UNIT_COST          BOH         IN  EOH         OUT  LOSS
     VN034P1      350      0       0     350        0   350   88,169.854   24,496,087  6,363,362    0  30,859,449     0
     VN034P2      293     20       0     310        3   310  114,138.219   19,460,992 15,921,856    0  35,382,848     0
     VN034P3      242     20       0     260        2   260   29,774.162    5,855,910  1,885,372    0   7,741,282     0
     ─────────────────────────────────────────────────────────────────────────────────────────────
     합계                                                                   49,812,989 24,170,590    0  73,983,579     0
     · 세 모델 모두 BOH+IN-LOSS = OUT 으로 완전 소진, EOH_QTY=0 이라 EOH 금액 0
     · DENOM 이 350/310/260 으로 모두 >0 → 전량손실 아님 → LOSS 금액 0
       (부분 LOSS 는 수량만 표시하고 금액은 양품이 흡수 — 일반 브랜치와 동일 규칙)
     · 항등식 BOH+IN-EOH-OUT-LOSS = 0 : 81행 전부 0

   ■ 현행 코드로 202608 을 돌릴 경우 (대조군, 동일 소스 재현)
     VN034P1 DENOM=0  → OUT 0 / LOSS 6,363,362   (IN_QTY=0·LOSS_QTY=0 이라 '전량손실' 오분류)
     VN034P2 DENOM=17 → 단가 936,579 (정상 114,138 의 8.2배)
     VN034P3 DENOM=18 → 단가 104,743 (정상 29,774 의 3.5배)
     기초재공 49,812,989 전액 소멸. 제품제조원가 17,807,228 (정상 73,983,579 대비 56,176,351 과소)

   ■ 회귀 안전성
     202607 은 BOH=0 이므로 POOL_ROW=IN_ROW, DENOM 동일 →
     78행 전체의 EOH/OUT/LOSS/IN/BOH/UNIT_COST 차이 0 (운영DB SELECT 재현으로 검증).
     따라서 202607 이전 소급 재결산은 불필요하다.

   ■ 적용 절차
     1. 라이브 정의 백업 : SELECT OBJECT_DEFINITION(OBJECT_ID('UP_DOI_COST'))
        → db/hq_procs/UP_DOI_COST_bak260911.sql 로 저장 (저장소본을 그대로 배포하지 말 것)
     2. 백업본에서 L458~L511 블록을 아래 대체본으로 교체 후 ALTER PROCEDURE 배포
     3. 202608 결산 재실행 : UP_DOI_EXPEN_MATL → UP_DOI_MAT_COST → UP_DOI_MAT_AMT →
        UP_DOI_COST → UP_DOI_STOCK_BOH → UP_DOI_STOCK_COST → UP_DOI_SALE_COST
        (카세트 원가가 +56.2M 움직이므로 제품원가·매출원가까지 전부 다시 타야 한다)
     4. 아래 대사 쿼리로 확인

   ■ 적용 후 대사
     -- (a) 전월 EOH = 당월 BOH
     SELECT (SELECT SUM(EOH) FROM DOI_COST WHERE YYYYMM='202607' AND SITE='HQ' AND MODEL LIKE 'VN%') AS 전월EOH,
            (SELECT SUM(BOH) FROM DOI_COST WHERE YYYYMM='202608' AND SITE='HQ' AND MODEL LIKE 'VN%') AS 당월BOH;
            -- 둘 다 49,812,989 이어야 한다
     -- (b) 항등식
     SELECT COUNT(*) FROM DOI_COST WHERE YYYYMM='202608' AND SITE='HQ' AND MODEL LIKE 'VN%'
       AND ROUND(ISNULL(BOH,0)+ISNULL([IN],0)-ISNULL(EOH,0)-ISNULL([OUT],0)-ISNULL(LOSS,0),0) <> 0;
            -- 0 이어야 한다
     -- (c) 총액
     SELECT MODEL, SUM(BOH) BOH, SUM([IN]) [IN], SUM(EOH) EOH, SUM([OUT]) [OUT], SUM(LOSS) LOSS
       FROM DOI_COST WHERE YYYYMM='202608' AND SITE='HQ' AND MODEL LIKE 'VN%' GROUP BY MODEL;

   ■ 오너 판단이 필요한 잔여 항목 (이번 수정 범위 밖)
     · ADJ_QTY 가 IN_QTY 로 들어간다. 202608 VN034P1 은 IN_QTY=0 이라 ADJ_QTY=0 인데
       BOH_QTY 350 · OUT_QTY 350 이다. DOI_COST.ADJ_QTY 를 읽는 하류 프로시저는 없어
       금액 영향은 없으나, BOH 도입과 의미상 맞추려면 BOH_QTY+IN_QTY 로 볼지 결정 필요.
     · 전량손실 센티넬이 DENOM<=0 이라 '무활동(BOH 금액만 있고 수량 전부 0)' 과 구분되지 않는다.
       202608 은 3모델 모두 생산수불 행이 있어 해당 없으나, 향후 생산수불 행이 없는 달에는
       기초재공이 LOSS 로 상각될 수 있다. 일반 브랜치 규칙(BOH_QTY+IN_QTY = LOSS_QTY)으로
       좁히는 것을 권고한다.
     · 카세트 EOH 평가는 완성도 100%(POOL×EOH_QTY/DENOM), 일반 브랜치는 50%(단가×EOH_QTY/2) 로
       기준이 다르다. 기존 확정사항이면 주석으로 근거를 남기고, 아니면 통일 필요.
     · FRAC 가 decimal 스케일 축약으로 0/1 두 값만 가져 largest-remainder 가 근사 동작한다.
       총액은 보존되어 재무 영향은 없다(기존 결함, 이번 수정과 무관).

   ============================================================================
   아래가 L458~L511 을 대체할 블록이다.
   ============================================================================ */


     ;WITH base AS (
      -- [카세트 경비] doi_expen_matl 카세트 배부분
      SELECT A.YYYYMM AS YYYYMM, a.sel_code AS sel_code, A.SITE AS SITE, B.구분 AS 구분, A.CST_NO AS MODEL,
             B.EXPEN_SEL명 AS EXPEN_SEL명, B.ACCT_NAME AS ACCT_NAME, B.SUB_NAME AS ITEM_NAME, B.EXPEN_SEL AS EXPEN_SEL,
             CAST(ISNULL([IN],0) AS DECIMAL(38,6)) AS IN_ROW,                 -- [변경] ISNULL : STEP8 MERGE 신규행([IN] NULL) 방어
             CAST(ISNULL(B.BOH  ,0) AS DECIMAL(38,6)) AS BOH_ROW,             -- [추가] 전월EOH -> 당월BOH (UP_DOI_EXPEN_MATL STEP8 MERGE 결과)
             CAST(ISNULL(ps.BOH_MONTH,0) AS INT)      AS BOH_QTY,             -- [추가] 기초재공 수량(생산수불)
             ISNULL(ps.IN_MONTH,0) AS IN_QTY, ISNULL(ps.EOH_MONTH,0) AS EOH_QTY,
             ISNULL(ps.OUT_MONTH,0) AS OUT_QTY, ISNULL(ps.LOSS_MONTH,0) AS LOSS_QTY, ISNULL(ps.공정발생불량,0) AS DEFECT_QTY
      FROM doi_vncst_rate a
        INNER JOIN doi_expen_matl b ON (a.yyyymm=b.yyyymm and a.site=b.site and a.cst_no=b.model and b.sel_code=@SEL_CODE)
        LEFT JOIN DOI_PROD_SUBUL ps ON (ps.yyyymm=a.yyyymm and ps.site=a.site and ps.sel_code=@SEL_CODE and ps.도우코드=a.cst_no)
      WHERE a.yyyymm=@YYYYMM and a.site=@SITE and a.cst_no LIKE 'VN034P[0-9]'
      UNION ALL
      -- [카세트 재료비] doi_mat_cost 카세트 배부분
      SELECT m.YYYYMM, m.SEL_CODE, m.SITE, N'양산', m.도우모델,
             CASE WHEN m.mat_class=N'원자재' THEN N'직접재료비' ELSE N'간접재료비' END,
             CASE WHEN m.mat_gubun=N'제품' AND m.mat_class=N'원자재' THEN N'원장'
                  WHEN m.자재대분류=N'필름' THEN 'PF' WHEN m.자재대분류=N'트레이' THEN N'트레이'
                  WHEN m.mat_class=N'약액' THEN N'약액' WHEN m.mat_class=N'더미글라스' THEN N'더미글라스' ELSE N'기타' END,
             m.자재번호, CASE WHEN m.mat_class=N'원자재' THEN 'MDAX' ELSE 'MIAX' END,
             CAST(ISNULL(m.배부금액,0) AS DECIMAL(38,6)),                      -- [변경] ISNULL : 전월EOH MERGE 신규행(배부금액 0/NULL) 방어
             CAST(ISNULL(m.BOH_AMT ,0) AS DECIMAL(38,6)),                     -- [추가] 전월EOH -> 당월BOH (UP_DOI_MAT_COST 전월_EOH MERGE 결과)
             CAST(ISNULL(ps.BOH_MONTH,0) AS INT),                             -- [추가] 기초재공 수량(생산수불)
             ISNULL(ps.IN_MONTH,0), ISNULL(ps.EOH_MONTH,0), ISNULL(ps.OUT_MONTH,0), ISNULL(ps.LOSS_MONTH,0), ISNULL(ps.공정발생불량,0)
      FROM doi_mat_cost m
        LEFT JOIN DOI_PROD_SUBUL ps ON (ps.yyyymm=m.yyyymm and ps.site=m.site and ps.sel_code=m.sel_code and ps.도우코드=m.도우모델)
      WHERE m.yyyymm=@YYYYMM and m.site=@SITE and m.sel_code=@SEL_CODE and m.도우모델 LIKE 'VN034P[0-9]'
   ),
   calc AS (
      -- 제품(도우코드)단위 재공품단가 = 제품POOL금액(기초+투입) / (기초수량 + 투입수량 - LOSS수량)
      SELECT b.*, (BOH_ROW + IN_ROW) AS POOL_ROW,                             -- [추가] 행 POOL = 기초 + 당월투입
             (BOH_QTY + IN_QTY - LOSS_QTY) AS DENOM,                          -- [변경] 분모에 BOH_QTY 가산
             SUM(BOH_ROW + IN_ROW) OVER (PARTITION BY MODEL) AS IN_PROD       -- [변경] 제품 POOL 금액(기초+투입)
      FROM base b
   ),
   r1 AS (
      SELECT c.*,
        CASE WHEN DENOM<=0 THEN CAST(0 AS DECIMAL(38,6)) ELSE IN_PROD/CAST(DENOM AS DECIMAL(38,6)) END AS UNIT,
        CASE WHEN DENOM<=0 THEN CAST(0 AS DECIMAL(38,6)) ELSE POOL_ROW*CAST(EOH_QTY AS DECIMAL(38,6))/CAST(DENOM AS DECIMAL(38,6)) END AS EOH_EXACT,  -- [변경] IN_ROW->POOL_ROW
        CASE WHEN DENOM<=0 THEN CAST(0 AS DECIMAL(38,0)) ELSE FLOOR(CAST(EOH_QTY AS DECIMAL(38,6))*IN_PROD/CAST(DENOM AS DECIMAL(38,6))) END AS EOH_PROD
      FROM calc c
   ),
   r2 AS ( SELECT r1.*, FLOOR(EOH_EXACT) AS EOH_FLOOR, (EOH_EXACT-FLOOR(EOH_EXACT)) AS FRAC FROM r1 ),
   r3 AS ( SELECT r2.*, SUM(EOH_FLOOR) OVER (PARTITION BY MODEL) AS SUM_FLOOR,
             ROW_NUMBER() OVER (PARTITION BY MODEL ORDER BY FRAC DESC, POOL_ROW DESC, ITEM_NAME) AS RN FROM r2 ),  -- [변경] 타이브레이크 IN_ROW->POOL_ROW
   -- EOH(재공) = 제품 FLOOR값이 되도록 행별 FLOOR + 소수부 큰 행부터 잔차 +1 배분(largest-remainder)
   r4 AS ( SELECT r3.*, (EOH_FLOOR + CASE WHEN RN <= (EOH_PROD-SUM_FLOOR) THEN 1 ELSE 0 END) AS EOH_ROW FROM r3 )
   INSERT INTO DOI_COST
     (YYYYMM,sel_code,SITE,구분,MODEL,EXPEN_SEL명,ACCT_NAME,ITEM_NAME,EXPEN_SEL,
      BOH_QTY,IN_QTY,EOH_QTY,OUT_QTY,LOSS_QTY,BAD_QTY,TRANSFER_QTY,ADJ_QTY,UNIT_COST,OUT_단가,BOH,[IN],EOH,[OUT],LOSS,ADJ_YN,UnitCost_YN,LOSS_DEFECT_QTY,LOSS_DEFECT_AMT)
     SELECT YYYYMM,sel_code,SITE,구분,MODEL,EXPEN_SEL명,ACCT_NAME,ITEM_NAME,EXPEN_SEL,
       BOH_QTY, IN_QTY, EOH_QTY, OUT_QTY, LOSS_QTY, 0, 0, IN_QTY,             -- [변경] 첫 항목 리터럴 0 -> BOH_QTY
       UNIT AS UNIT_COST, UNIT AS OUT_단가, BOH_ROW AS BOH, IN_ROW AS [IN],    -- [추가] BOH_ROW AS BOH
       EOH_ROW AS EOH,                                                              -- 기말재공평가 = 재공수량 x 재공품단가 (제품 FLOOR + 잔차배분)
       (POOL_ROW - EOH_ROW - CASE WHEN DENOM<=0 AND POOL_ROW<>0 THEN POOL_ROW ELSE 0 END) AS [OUT],  -- 제품제조원가 = 기초+투입 - EOH - LOSS
       CASE WHEN DENOM<=0 AND POOL_ROW<>0 THEN POOL_ROW ELSE 0 END AS LOSS,         -- 전량손실(boh_qty+in_qty=loss_qty)일 때만 금액
       'Y' AS ADJ_YN, 1 AS UnitCost_YN,
       CASE WHEN @SITE='HQ' THEN DEFECT_QTY ELSE 0 END AS LOSS_DEFECT_QTY,
       CASE WHEN DENOM<=0 AND POOL_ROW<>0 THEN POOL_ROW ELSE 0 END AS LOSS_DEFECT_AMT
     FROM r4;