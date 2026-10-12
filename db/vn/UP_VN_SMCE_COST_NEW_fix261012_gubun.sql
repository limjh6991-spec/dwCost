
/* ============================================================================
   [2026-10-12] UP_VN_SMCE_COST_NEW (판관비 배부) — 구분(양산/개발) 판정규칙 정정
   ----------------------------------------------------------------------------
   근본원인: 구분 판정이 'RIGHT(품번,1)=D → 개발 ELSE 양산' 으로, 시스템 정규규칙
             'RIGHT(품번,1)=P → 양산 ELSE 개발' 과 반대. 품번 끝글자가 P/D가 아닌
             모델(예 717NTT·716ETT, 끝글자 T)이 배부 데이터(DOI_SMCE_COST)에만
             '양산'으로 잘못 기록 → 판관비 집계표가 '양산717NTT'로 표기되는 근원.
   수정: 정규규칙으로 교체 (VN%→카세트, RIGHT='P'→양산, ELSE 개발).
   영향: DIST_AMT(배부금액)는 매출비율 기준이라 불변. 끝글자 P/D가 아닌 모델의
         구분 라벨만 양산→개발로 교정(202608=717NTT 1종).
   주의: 배부 결과 테이블 재생성 → 적용 후 EXEC UP_VN_SMCE_COST_NEW '202608','VN','ACTUAL' 재실행 필요.
         DOI_SMCE_COST 만 DELETE+INSERT(리포트 전용 소비). 전체 재결산/JAR 불필요.
         백업 db/vn/UP_VN_SMCE_COST_NEW_bak261012.sql
   ============================================================================ */
ALTER PROCEDURE UP_VN_SMCE_COST_NEW
    @YYYYMM varchar(6), @SITE varchar(4)='VN', @SEL_CODE varchar(6)='ACTUAL'
AS
BEGIN
    SET NOCOUNT ON;
    -- [VN 260821] 판관비: doi_acct_expen(CC) 을 매출(doi_invoice_resc)비율 배부. model=도우모델(LEFT(품번,LEN-1)) → 리포트 DOI_VN_STCO.MODEL 조인 일치.
    DELETE FROM DOI_SMCE_COST WHERE yyyymm=@YYYYMM AND SITE=@SITE AND SEL_CODE=@SEL_CODE;
    WITH sale_data AS (
        SELECT 구분, model, Local구분, 판매단위, 거래처, SUM(SALE_AMT) SALE_AMT FROM (
            SELECT CASE WHEN 품번 LIKE N'VN%' THEN N'카세트' WHEN RIGHT(품번,1)='P' THEN N'양산' ELSE N'개발' END 구분,   /* [261012] 정규 구분규칙으로 정정 (기존 D→개발 반대규칙 버그) */
                   CASE WHEN LEN(품번)>1 THEN LEFT(품번,LEN(품번)-1) ELSE 품번 END model,
                   N'일반수출' Local구분, N'CELL' 판매단위, N'*' 거래처, CAST(원화판매금액 AS float) SALE_AMT
            FROM DOI_INVOICE_RESC WHERE yyyymm=@YYYYMM AND site=@SITE
        ) x GROUP BY 구분, model, Local구분, 판매단위, 거래처
    ),
    sale_total AS (SELECT SUM(SALE_AMT) TOT_SALE_AMT FROM sale_data),
    expen_data AS (
        SELECT YYYYMM, SITE, ACCT_NAME SUB_NAME, MAX(ITEM_NAME) ITEM_NAME, EXPEN_SEL, MIN(EXPEN_SEL명) EXPEN_SEL명,
               SUM(CAST(ACCT_AMT AS float)) TOT_ACCT, SUM(SUM(CAST(ACCT_AMT AS float))) OVER() TOT_SMCE
        FROM DOI_ACCT_EXPEN
        WHERE yyyymm=@YYYYMM AND site=@SITE AND acct_class='CC' AND sel_code=@SEL_CODE
        GROUP BY YYYYMM, SITE, EXPEN_SEL, ACCT_NAME
    )
    INSERT INTO DOI_SMCE_COST (YYYYMM, sel_code, SITE, 구분, model, Local구분, 판매단위, 거래처, EXPEN_SEL명, SUB_NAME, ITEM_NAME, EXPEN_SEL, TOT_ACCT, SALE_AMT, TOT_AMT, TOT_SMCE, DIST_RATE, DIST_AMT, DIST_AMT_ORI)
    SELECT YYYYMM, @SEL_CODE, SITE, 구분, model, Local구분, 판매단위, 거래처, EXPEN_SEL명, SUB_NAME, ITEM_NAME, EXPEN_SEL,
        TOT_ACCT, SALE_AMT, TOT_AMT, TOT_SMCE, DIST_RATE,
        Base_Dist_Amt + CASE WHEN RN=1 THEN (TOT_ACCT - Grp_Sum_Amt) ELSE 0 END AS DIST_AMT,
        DIST_AMT_ORI
    FROM (
        SELECT A.*,
            SUM(Base_Dist_Amt) OVER (PARTITION BY EXPEN_SEL, SUB_NAME) AS Grp_Sum_Amt,
            ROW_NUMBER() OVER (PARTITION BY EXPEN_SEL, SUB_NAME ORDER BY SALE_AMT DESC) AS RN
        FROM (
            SELECT e.YYYYMM, e.SITE, s.구분, s.model, s.Local구분, s.판매단위, s.거래처,
                e.EXPEN_SEL명, e.SUB_NAME, e.ITEM_NAME, e.EXPEN_SEL, e.TOT_ACCT, e.TOT_SMCE,
                s.SALE_AMT, t.TOT_SALE_AMT TOT_AMT,
                CASE WHEN ISNULL(t.TOT_SALE_AMT,0)=0 THEN 0 ELSE CAST(s.SALE_AMT AS float)/t.TOT_SALE_AMT END DIST_RATE,
                CASE WHEN ISNULL(t.TOT_SALE_AMT,0)=0 THEN 0 ELSE ROUND(e.TOT_ACCT*(CAST(s.SALE_AMT AS float)/t.TOT_SALE_AMT),2) END Base_Dist_Amt,
                e.TOT_ACCT*(CAST(s.SALE_AMT AS float)/NULLIF(t.TOT_SALE_AMT,0)) DIST_AMT_ORI
            FROM expen_data e CROSS JOIN sale_data s CROSS JOIN sale_total t
        ) A
    ) Final;
    SELECT @@ROWCOUNT AS inserted;
END
