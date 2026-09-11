/* ============================================================================
   UP_DOI_COST  -  카세트(VINA CST) 전용 INSERT 블록  [라이브 L458~L511 대체본]
   2026-09-11  기초재공(BOH) 미반영 결함 수정

   변경 요지 (4곳만, CTE 구조/largest-remainder/LOSS 규칙 불변)
     (1) base   : BOH_ROW(기초금액) / BOH_QTY(기초수량) 컬럼 추가 + [IN] ISNULL 방어
     (2) calc   : POOL_ROW = BOH_ROW+IN_ROW,  DENOM = BOH_QTY+IN_QTY-LOSS_QTY,
                  IN_PROD  = SUM(POOL_ROW)  (제품 POOL 금액)
     (3) r1/r3  : EOH 안분 분자 IN_ROW -> POOL_ROW (정렬 타이브레이크도 동일)
     (4) INSERT : 컬럼목록에 BOH 추가, BOH_QTY 리터럴 0 -> BOH_QTY,
                  [OUT]/LOSS/LOSS_DEFECT_AMT 의 IN_ROW -> POOL_ROW

   회귀 근거 : 202607 은 BOH=0(카세트 첫 달) 이므로 POOL_ROW=IN_ROW, DENOM 동일 ->
              78행 전체 EOH/OUT/LOSS/IN/BOH/UNIT_COST 차이 0 (운영DB SELECT 재현 검증)
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
