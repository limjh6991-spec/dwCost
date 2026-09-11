/* =====================================================================================
   UP_DOI_COST  -  [카세트(VINA CST) 전용 INSERT 블록] 교체본
   ---------------------------------------------------------------------------------
   2026-09-11 : 전월 재공 기초(BOH) 미반영 결함 수정
     - 전월 DOI_COST 의 카세트 EOH 를 (MODEL, EXPEN_SEL, ACCT_NAME, ITEM_NAME) 그레인으로
       직접 읽어 당월 BOH 로 승계  (상류 MERGE 의존 없음)
     - BOH_QTY = DOI_PROD_SUBUL.BOH_MONTH (제품단위)
     - 재공품단가 분모 DENOM = BOH_QTY + IN_QTY - LOSS_QTY  (가중평균 유지)
     - LOSS 금액 = 전량손실(BOH_QTY+IN_QTY = LOSS_QTY) 일 때만 (BOH+IN), 그 외 0
       (일반 브랜치 규칙과 동일. 부분 LOSS 는 수량만 표시)
     - 2026-08-14 도입한 largest-remainder EOH 잔차배분 구조는 그대로 유지
   ---------------------------------------------------------------------------------
   라이브 원본은 이 블록 시작(;WITH base AS ...) ~ 끝(FROM r4;) 까지를 통째로 교체할 것.
   ===================================================================================== */

     DECLARE @CST_PREV_YM VARCHAR(6) = FORMAT(DATEADD(MONTH,-1, LEFT(@YYYYMM,6) + '01'), 'yyyyMM');

     ;WITH qty AS (
        -- 제품(도우코드)별 당월 수불수량 : 카세트 3제품
        SELECT ps.도우코드                             AS MODEL,
               CAST(ISNULL(ps.BOH_MONTH ,0) AS INT)    AS BOH_QTY,
               CAST(ISNULL(ps.IN_MONTH  ,0) AS INT)    AS IN_QTY,
               CAST(ISNULL(ps.EOH_MONTH ,0) AS INT)    AS EOH_QTY,
               CAST(ISNULL(ps.OUT_MONTH ,0) AS INT)    AS OUT_QTY,
               CAST(ISNULL(ps.LOSS_MONTH,0) AS INT)    AS LOSS_QTY,
               CAST(ISNULL(ps.공정발생불량,0) AS INT)   AS DEFECT_QTY
        FROM DOI_PROD_SUBUL ps
        WHERE ps.yyyymm=@YYYYMM AND ps.site=@SITE AND ps.sel_code=@SEL_CODE
          AND ps.도우코드 LIKE 'VN034P[0-9]'
     ),
     cur AS (
        -- [카세트 경비] doi_expen_matl 카세트 배부분
        SELECT A.CST_NO AS MODEL, B.구분 AS 구분, B.EXPEN_SEL명 AS EXPEN_SEL명,
               B.ACCT_NAME AS ACCT_NAME, B.SUB_NAME AS ITEM_NAME, B.EXPEN_SEL AS EXPEN_SEL,
               CAST(ISNULL(B.[IN],0) AS DECIMAL(38,6)) AS IN_ROW   -- 상류 MERGE 신규행은 [IN] NULL → 0
        FROM doi_vncst_rate a
          INNER JOIN doi_expen_matl b ON (a.yyyymm=b.yyyymm and a.site=b.site and a.cst_no=b.model and b.sel_code=@SEL_CODE)
        WHERE a.yyyymm=@YYYYMM and a.site=@SITE and a.cst_no LIKE 'VN034P[0-9]'
        UNION ALL
        -- [카세트 재료비] doi_mat_cost 카세트 배부분
        SELECT m.도우모델, N'양산',
               CASE WHEN m.mat_class=N'원자재' THEN N'직접재료비' ELSE N'간접재료비' END,
               CASE WHEN m.mat_gubun=N'제품' AND m.mat_class=N'원자재' THEN N'원장'
                    WHEN m.자재대분류=N'필름' THEN 'PF' WHEN m.자재대분류=N'트레이' THEN N'트레이'
                    WHEN m.mat_class=N'약액' THEN N'약액' WHEN m.mat_class=N'더미글라스' THEN N'더미글라스' ELSE N'기타' END,
               m.자재번호, CASE WHEN m.mat_class=N'원자재' THEN 'MDAX' ELSE 'MIAX' END,
               CAST(ISNULL(m.배부금액,0) AS DECIMAL(38,6))
        FROM doi_mat_cost m
        WHERE m.yyyymm=@YYYYMM and m.site=@SITE and m.sel_code=@SEL_CODE and m.도우모델 LIKE 'VN034P[0-9]'
     ),
     cur_g AS (
        -- 그레인 정규화(중복행 합산) : 전월 BOH 조인 시 BOH 중복증폭 방지
        SELECT MODEL, ACCT_NAME, ITEM_NAME, EXPEN_SEL,
               MAX(구분) AS 구분, MAX(EXPEN_SEL명) AS EXPEN_SEL명,
               SUM(IN_ROW) AS IN_ROW
        FROM cur
        GROUP BY MODEL, ACCT_NAME, ITEM_NAME, EXPEN_SEL
     ),
     prv AS (
        -- [기초재공] 전월 DOI_COST 카세트 기말재공평가액 → 당월 BOH
        SELECT MODEL, ACCT_NAME, ITEM_NAME, EXPEN_SEL,
               MAX(구분) AS 구분, MAX(expen_sel명) AS EXPEN_SEL명,
               CAST(SUM(EOH) AS DECIMAL(38,6)) AS BOH_ROW
        FROM DOI_COST
        WHERE YYYYMM=@CST_PREV_YM AND SITE=@SITE AND SEL_CODE=@SEL_CODE
          AND MODEL LIKE 'VN034P[0-9]' AND EOH<>0
        GROUP BY MODEL, ACCT_NAME, ITEM_NAME, EXPEN_SEL
     ),
     base AS (
        -- 당월배부(cur_g) ∪ 전월기초(prv) : 어느 한 쪽에만 있는 행도 누락 없이 포함
        SELECT @YYYYMM AS YYYYMM, @SEL_CODE AS sel_code, @SITE AS SITE,
               COALESCE(c.MODEL      ,p.MODEL)          AS MODEL,
               COALESCE(c.구분       ,p.구분, N'양산')   AS 구분,
               COALESCE(c.EXPEN_SEL명,p.EXPEN_SEL명)     AS EXPEN_SEL명,
               COALESCE(c.ACCT_NAME  ,p.ACCT_NAME)      AS ACCT_NAME,
               COALESCE(c.ITEM_NAME  ,p.ITEM_NAME)      AS ITEM_NAME,
               COALESCE(c.EXPEN_SEL  ,p.EXPEN_SEL)      AS EXPEN_SEL,
               ISNULL(p.BOH_ROW,0) AS BOH_ROW,
               ISNULL(c.IN_ROW ,0) AS IN_ROW,
               ISNULL(q.BOH_QTY   ,0) AS BOH_QTY, ISNULL(q.IN_QTY  ,0) AS IN_QTY,
               ISNULL(q.EOH_QTY   ,0) AS EOH_QTY, ISNULL(q.OUT_QTY ,0) AS OUT_QTY,
               ISNULL(q.LOSS_QTY  ,0) AS LOSS_QTY, ISNULL(q.DEFECT_QTY,0) AS DEFECT_QTY
        FROM cur_g c
          FULL OUTER JOIN prv p
            ON (p.MODEL=c.MODEL AND p.EXPEN_SEL=c.EXPEN_SEL AND p.ACCT_NAME=c.ACCT_NAME AND p.ITEM_NAME=c.ITEM_NAME)
          LEFT JOIN qty q ON q.MODEL = COALESCE(c.MODEL,p.MODEL)
     ),
     calc AS (
        -- 제품(도우코드)단위 재공품단가 = (기초재공+당월투입) / (기초수량+투입수량-LOSS수량)
        SELECT b.*,
               (BOH_ROW + IN_ROW) AS POOL_ROW,
               CAST(BOH_QTY + IN_QTY - LOSS_QTY AS DECIMAL(38,6)) AS DENOM,
               CASE WHEN (BOH_QTY+IN_QTY) > 0 AND (BOH_QTY+IN_QTY) = LOSS_QTY THEN 1 ELSE 0 END AS ALLLOSS,
               SUM(BOH_ROW + IN_ROW) OVER (PARTITION BY MODEL) AS POOL_PROD
        FROM base b
     ),
     r1 AS (
        SELECT c.*,
          CASE WHEN ALLLOSS=1 OR DENOM<=0 THEN CAST(0 AS DECIMAL(38,6)) ELSE POOL_PROD/DENOM END AS UNIT,
          CASE WHEN ALLLOSS=1 OR DENOM<=0 THEN CAST(0 AS DECIMAL(38,6)) ELSE POOL_ROW*CAST(EOH_QTY AS DECIMAL(38,6))/DENOM END AS EOH_EXACT,
          CASE WHEN ALLLOSS=1 OR DENOM<=0 THEN CAST(0 AS DECIMAL(38,0)) ELSE FLOOR(CAST(EOH_QTY AS DECIMAL(38,6))*POOL_PROD/DENOM) END AS EOH_PROD
        FROM calc c
     ),
     r2 AS ( SELECT r1.*, FLOOR(EOH_EXACT) AS EOH_FLOOR, (EOH_EXACT-FLOOR(EOH_EXACT)) AS FRAC FROM r1 ),
     r3 AS ( SELECT r2.*, SUM(EOH_FLOOR) OVER (PARTITION BY MODEL) AS SUM_FLOOR,
               ROW_NUMBER() OVER (PARTITION BY MODEL ORDER BY FRAC DESC, POOL_ROW DESC, ITEM_NAME, EXPEN_SEL, ACCT_NAME) AS RN FROM r2 ),
     -- EOH(재공) = 제품 FLOOR값이 되도록 행별 FLOOR + 소수부 큰 행부터 잔차 +1 배분(largest-remainder)
     r4 AS ( SELECT r3.*, (EOH_FLOOR + CASE WHEN RN <= (EOH_PROD-SUM_FLOOR) THEN 1 ELSE 0 END) AS EOH_ROW FROM r3 )
     INSERT INTO DOI_COST
       (YYYYMM,sel_code,SITE,구분,MODEL,EXPEN_SEL명,ACCT_NAME,ITEM_NAME,EXPEN_SEL,
        BOH_QTY,IN_QTY,EOH_QTY,OUT_QTY,LOSS_QTY,BAD_QTY,TRANSFER_QTY,ADJ_QTY,UNIT_COST,OUT_단가,BOH,[IN],EOH,[OUT],LOSS,ADJ_YN,UnitCost_YN,LOSS_DEFECT_QTY,LOSS_DEFECT_AMT)
       SELECT YYYYMM,sel_code,SITE,구분,MODEL,EXPEN_SEL명,ACCT_NAME,ITEM_NAME,EXPEN_SEL,
         BOH_QTY, IN_QTY, EOH_QTY, OUT_QTY, LOSS_QTY, 0, 0, IN_QTY,
         UNIT AS UNIT_COST, UNIT AS OUT_단가,
         BOH_ROW AS BOH,                                                            -- 기초재공 = 전월 DOI_COST 기말재공
         IN_ROW  AS [IN],
         EOH_ROW AS EOH,                                                            -- 기말재공평가 = 재공수량 x 재공품단가 (제품 FLOOR + 잔차배분)
         (POOL_ROW - EOH_ROW - CASE WHEN ALLLOSS=1 THEN POOL_ROW ELSE 0 END) AS [OUT],  -- 제품제조원가 = BOH + IN - EOH - LOSS
         CASE WHEN ALLLOSS=1 THEN POOL_ROW ELSE 0 END AS LOSS,                      -- 전량손실(BOH수량+IN수량=LOSS수량)일 때만 금액
         'Y' AS ADJ_YN, 1 AS UnitCost_YN,
         CASE WHEN @SITE='HQ' THEN DEFECT_QTY ELSE 0 END AS LOSS_DEFECT_QTY,
         CASE WHEN ALLLOSS=1 THEN POOL_ROW ELSE 0 END AS LOSS_DEFECT_AMT
       FROM r4;
