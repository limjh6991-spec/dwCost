/* ============================================================================
   VN 전용 연간 경영 실행(P&L 트렌드) 프로시저  —  C0008014 "경영 실행"
   ----------------------------------------------------------------------------
   [배경]
     · C0008014_Sch1 은 HQ 전용 DOI_AnnualReportBySite(SITE='HQ' 하드코딩 다수 +
       연도 '2025' 하드코딩 + Buyer!='도우VINA' + 소스 DOI_COST/DOI_STCO 사용)를 호출.
       DOI_COST/DOI_STCO 는 VN _NEW 결산체인이 갱신하지 않아 VN에선 stale/0.
     · 본 프로시저는 VN _NEW 결산 산출물에서 동일 그리드(구분 × tot × 1월~12월)를 산출.
       매퍼 C0008014_Sch1 에서 site='VN' 일 때 이 프로시저로 분기(HQ 는 기존 유지).

   [출력 계약 — 프론트 무수정]
     · 컬럼: 구분(TEXT), tot(NUMBER, "년 실행"), 1월~12월(NUMBER)
     · 금액행 tot = 12개월 합. 비율행 tot = 연간율(연간GP/OP ÷ 연간매출).

   [핵심 정합성 — VN 월별 손익(VN_PL_ByModel)과 tie-out]
     상단 P&L 라인은 VN_PL_ByModel(=C0008016 손익계산서, 검증완료)의 Z합계(사이트합)와
     동일한 원천식을 월별로 그대로 사용 → 각 월 컬럼이 월손익과 일치.
       · 매출액        = SUM(원화판매금액: DOI_SALE_RESC+DOI_INVOICE_RESC) − 유상사급(DOI_원장상계.매출상계)
       · 제품매출원가  = SUM(doi_vn_stco.T_OUTPUT_AMT) + 조정(doi_slco expen_sel명='기타매출'.OUT_AMT)
       · 상품매출원가  = SUM(doi_matl_resc.출고금액 where 품목자산분류='상품')
       · 매출총이익    = 매출액 − (제품매출원가 + 상품매출원가)
       · 판매비와관리비= SUM(doi_smce_cost.DIST_AMT) : doi_dept_cost(비용구분='판관')→doi_acct 브리지,
                          상위계정과목 <> '비용제외'/공백
       · 영업이익      = 매출총이익 − 판매비와관리비
       · 판관비 27세부 = COALESCE(경영계획과목,상위계정과목) 기준 (VN_PL_ByModel PL_SGNA 골격 동일)

   [제조원가 내역 세목 — VN_ManufacturingExpenseByModel(C0009005, 검증완료)과 동일 계보]
       · 재료비(원/부)          = doi_expn_matl(원가구분='재료비', EXPEN_SEL='MDAX'=원재료 그외 부재료)
       · 직접노무비(11세목)     = doi_expn_matl(원가구분='가공비')→doi_dept_cost→doi_acct 브리지, 계정코드 622*
       · 간접제조경비(33세목)   = 동일 브리지, 계정코드 627*(6272 부재료 제외)
         - 세목 = REPLACE(상위계정과목,'(간접)',''), 공구 및 도구비용은 특례 표기
         - 헤더(직접노무비/간접제조경비) = 해당 세목 합, ∴ 재료비+노무비+경비 = 당기총제조원가
       · 당기총제조원가        = 재료비 + 직접노무비 + 간접제조경비 (= C0009005 IV 당기총제조원가)
       · 기초/기말 제품재고    = doi_vn_stco(BOH_AMT / T_INPUT_AMT / EOH_WH0006_AMT)
       · 기초/기말 재공재고    = doi_vn_cost(BOH/EOH 8포지션 금액합)

   [제약]  SEL_CODE 내부고정 'ACTUAL'. doi_vn_stco 는 VN 전용(SITE 컬럼 없음).
           프로시저 시그니처는 HQ 와 동일(@YYYY,@SITE) → 매퍼 site 분기만 추가.
   ============================================================================ */
CREATE OR ALTER PROCEDURE VN_AnnualReportBySite
(
    @YYYY varchar(4),
    @SITE varchar(4)
)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        DECLARE @SEL_CODE varchar(10) = N'ACTUAL';

        ---------------------------------------------------------------------
        -- 0. 12개월 달력
        ---------------------------------------------------------------------
        ;WITH GEN AS (
            SELECT CAST(@YYYY + '0101' AS DATE) AS DT
            UNION ALL
            SELECT DATEADD(MONTH, 1, DT) FROM GEN WHERE DT < CAST(@YYYY + '1201' AS DATE)
        )
        SELECT FORMAT(DT, 'yyyyMM') AS YYYYMM, MONTH(DT) AS 월번호
        INTO #CAL
        FROM GEN
        OPTION (MAXRECURSION 12);

        ---------------------------------------------------------------------
        -- 1. 상품 품번 목록 (월별)  — 제품/상품 매출 분리 기준
        ---------------------------------------------------------------------
        SELECT DISTINCT YYYYMM, 품번
        INTO #MERCH
        FROM DOI_MATL_RESC WITH(NOLOCK)
        WHERE SITE = @SITE AND SEL_CODE = @SEL_CODE AND LEFT(YYYYMM,4) = @YYYY
          AND 품목자산분류 = N'상품' AND 품번 IS NOT NULL;

        ---------------------------------------------------------------------
        -- 2. 매출 (제품/상품/총/수량)  — DOI_SALE_RESC + DOI_INVOICE_RESC
        ---------------------------------------------------------------------
        SELECT s.YYYYMM,
               SUM(CASE WHEN m.품번 IS NULL     THEN s.amt ELSE 0 END) AS prod_sale,
               SUM(CASE WHEN m.품번 IS NOT NULL THEN s.amt ELSE 0 END) AS merch_sale,
               SUM(s.amt) AS total_sale,
               SUM(s.qty) AS qty
        INTO #SALE
        FROM (
            SELECT YYYYMM, 품번, CAST(원화판매금액 AS float) AS amt, CAST(수량 AS float) AS qty
            FROM DOI_SALE_RESC WITH(NOLOCK)
            WHERE SITE = @SITE AND LEFT(YYYYMM,4) = @YYYY
            UNION ALL
            SELECT YYYYMM, 품번, CAST(원화판매금액 AS float) AS amt, CAST(수량 AS float) AS qty
            FROM DOI_INVOICE_RESC WITH(NOLOCK)
            WHERE SITE = @SITE AND LEFT(YYYYMM,4) = @YYYY
        ) s
        LEFT JOIN #MERCH m ON m.YYYYMM = s.YYYYMM AND m.품번 = s.품번
        GROUP BY s.YYYYMM;

        ---------------------------------------------------------------------
        -- 3. 유상사급 (DOI_원장상계.매출상계)
        ---------------------------------------------------------------------
        SELECT YYYYMM, SUM(COALESCE(매출상계,0)) AS scof
        INTO #SCOF
        FROM DOI_원장상계 WITH(NOLOCK)
        WHERE SITE = @SITE AND SEL_CODE = @SEL_CODE AND LEFT(YYYYMM,4) = @YYYY
        GROUP BY YYYYMM;

        ---------------------------------------------------------------------
        -- 4. 상품매출원가 (DOI_MATL_RESC 출고금액, 품목자산분류='상품')
        ---------------------------------------------------------------------
        SELECT YYYYMM, SUM(ISNULL(출고금액,0)) AS merch_cogs
        INTO #MCOGS
        FROM DOI_MATL_RESC WITH(NOLOCK)
        WHERE SITE = @SITE AND SEL_CODE = @SEL_CODE AND LEFT(YYYYMM,4) = @YYYY
          AND 품목자산분류 = N'상품'
        GROUP BY YYYYMM;

        ---------------------------------------------------------------------
        -- 5. 제품 수불/원가 (doi_vn_stco) — VN 전용(SITE 컬럼 없음)
        ---------------------------------------------------------------------
        SELECT YYYYMM,
               SUM(ISNULL(BOH_AMT,0))          AS fg_boh,
               SUM(ISNULL(T_INPUT_AMT,0))      AS cur_mfg,
               SUM(ISNULL(EOH_WH0006_AMT,0))   AS fg_eoh,
               SUM(ISNULL(T_OUTPUT_AMT,0))     AS prod_cogs
        INTO #STCO
        FROM DOI_VN_STCO WITH(NOLOCK)
        WHERE SEL_CODE = @SEL_CODE AND LEFT(YYYYMM,4) = @YYYY
        GROUP BY YYYYMM;

        ---------------------------------------------------------------------
        -- 6. 제품매출원가 조정 (doi_slco expen_sel명='기타매출')
        ---------------------------------------------------------------------
        SELECT YYYYMM, SUM(ISNULL(OUT_AMT,0)) AS adj
        INTO #ADJ
        FROM doi_slco WITH(NOLOCK)
        WHERE SITE = @SITE AND SEL_CODE = @SEL_CODE AND LEFT(YYYYMM,4) = @YYYY
          AND expen_sel명 = N'기타매출'
        GROUP BY YYYYMM;

        ---------------------------------------------------------------------
        -- 7. 판관비 브리지 : doi_smce_cost → doi_dept_cost(판관) → doi_acct
        --    (VN_PL_ByModel SGNA 동일. 사이트합이므로 모델(도우코드) 조인은 생략)
        ---------------------------------------------------------------------
        SELECT B.YYYYMM,
               A.상위계정과목                                          AS 상위계정과목,
               COALESCE(NULLIF(A.경영계획과목,N''), A.상위계정과목)    AS item,
               CAST(ISNULL(B.DIST_AMT,0) AS float)                     AS amt
        INTO #SGNA_RAW
        FROM doi_smce_cost B WITH(NOLOCK)
        JOIN (SELECT yyyymm, site, 계정과목, MIN(계정코드) AS 계정코드
              FROM doi_dept_cost WITH(NOLOCK)
              WHERE 비용구분 = N'판관'
              GROUP BY yyyymm, site, 계정과목) dc
          ON dc.yyyymm = B.YYYYMM AND dc.site = B.SITE AND dc.계정과목 = B.SUB_NAME
        JOIN doi_acct A WITH(NOLOCK)
          ON A.yyyymm = B.YYYYMM AND A.site = B.SITE AND A.acct = dc.계정코드
        WHERE B.SITE = @SITE AND B.SEL_CODE = @SEL_CODE AND LEFT(B.YYYYMM,4) = @YYYY;

        -- 판관비 27 세부 골격 (VN_PL_ByModel PL_SGNA / VN_SalesAdminByModel 동일 목록·순서)
        SELECT seq, item
        INTO #SGSK
        FROM (VALUES
            (1,N'판)직원급여'),(2,N'판)상여금'),(3,N'판)제수당'),(4,N'판)퇴직급여'),(5,N'판)복리후생비'),
            (6,N'판)여비교통비'),(7,N'판)접대비'),(8,N'판)통신비'),(9,N'판)수도광열비'),(10,N'판)감가상각비'),
            (11,N'판)지급임차료'),(12,N'판)수선비'),(13,N'판)보험료'),(14,N'판)차량유지비'),(15,N'판)운반비'),
            (16,N'판)교육훈련비'),(17,N'판)도서인쇄비'),(18,N'판)소모품비'),(19,N'판)지급수수료'),(20,N'판)광고선전비'),
            (21,N'판)무형자산상각비'),(22,N'판)견본비'),(23,N'판)사용권자산감가상각비'),(24,N'판)주식보상비용'),(25,N'판)해외시장개척비'),
            (26,N'판)잡비'),(27,N'기술이전비 및 기술지원비')
        ) v(seq, item);

        ---------------------------------------------------------------------
        -- 8. 재료비 (doi_expn_matl 원가구분='재료비', EXPEN_SEL='MDAX'=원재료)
        ---------------------------------------------------------------------
        SELECT YYYYMM,
               SUM(CASE WHEN EXPEN_SEL = N'MDAX' THEN 투입금액 ELSE 0 END) AS raw_mat,
               SUM(CASE WHEN EXPEN_SEL <> N'MDAX' THEN 투입금액 ELSE 0 END) AS sub_mat,
               SUM(투입금액) AS mat_tot
        INTO #MAT
        FROM doi_expn_matl WITH(NOLOCK)
        WHERE SITE = @SITE AND SEL_CODE = @SEL_CODE AND LEFT(YYYYMM,4) = @YYYY
          AND 원가구분 = N'재료비'
        GROUP BY YYYYMM;

        ---------------------------------------------------------------------
        -- 9. 가공비 세목 브리지 (doi_expn_matl 원가구분='가공비')
        --    → doi_dept_cost → doi_acct.  sec 2=직접노무비(622*) / 3=간접제조경비(627*)
        --    세목 item = REPLACE(상위계정과목,'(간접)','') (공구 및 도구비용 특례)
        --    ※ VN_ManufacturingExpenseByModel(C0009005) 계보 동일 → 그 리포트와 tie-out
        ---------------------------------------------------------------------
        SELECT e.YYYYMM,
               CASE WHEN LEFT(dc.계정코드,3) = N'622' THEN 2 ELSE 3 END AS sec,
               CASE WHEN e.분류 = N'공구 및 도구비용 - 상각비용'   THEN N'제)공구 및 도구 비용 - 상각비용'
                    WHEN e.분류 = N'공구 및 도구비용 - 일회성비용' THEN N'제)공구 및 도구 비용 -일회성비용'
                    ELSE REPLACE(a.상위계정과목, N'(간접)', N'') END AS item,
               SUM(e.투입금액) AS amt
        INTO #FABD
        FROM (SELECT YYYYMM, SITE, 분류, 투입금액
              FROM doi_expn_matl WITH(NOLOCK)
              WHERE SITE = @SITE AND SEL_CODE = @SEL_CODE AND LEFT(YYYYMM,4) = @YYYY
                AND 원가구분 = N'가공비') e
        JOIN (SELECT yyyymm, site, 계정과목, MIN(계정코드) AS 계정코드
              FROM doi_dept_cost WITH(NOLOCK)
              WHERE LEFT(계정코드,3) IN (N'622', N'627') AND LEFT(계정코드,4) <> N'6272'
              GROUP BY yyyymm, site, 계정과목) dc
          ON dc.yyyymm = e.YYYYMM AND dc.site = e.SITE AND dc.계정과목 = e.분류
        JOIN doi_acct a WITH(NOLOCK)
          ON a.yyyymm = e.YYYYMM AND a.site = e.SITE AND a.acct = dc.계정코드
        WHERE ISNULL(REPLACE(a.상위계정과목, N'(간접)', N''), N'') <> N''
        GROUP BY e.YYYYMM,
                 CASE WHEN LEFT(dc.계정코드,3) = N'622' THEN 2 ELSE 3 END,
                 CASE WHEN e.분류 = N'공구 및 도구비용 - 상각비용'   THEN N'제)공구 및 도구 비용 - 상각비용'
                      WHEN e.분류 = N'공구 및 도구비용 - 일회성비용' THEN N'제)공구 및 도구 비용 -일회성비용'
                      ELSE REPLACE(a.상위계정과목, N'(간접)', N'') END;

        -- 가공비 세목 골격 (sec 2=직접노무비 11 / sec 3=간접제조경비 33) : C0009005 동일 목록
        SELECT sec, seq, item
        INTO #MSK
        FROM (VALUES
            -- 직접노무비 (622*)
            (2,1,N'제)급여-직원'),(2,2,N'제)상여금'),(2,3,N'제)제수당'),(2,4,N'제)퇴직급여'),(2,5,N'제)주식보상비용'),
            (2,6,N'제)급여-사회보험료'),(2,7,N'제)급여-건강보험'),(2,8,N'제)급여-노동자실업보험료'),(2,9,N'제)급여-노동자노조비'),
            (2,10,N'제)급여-개인소득세'),(2,11,N'제)급여-기타'),
            -- 간접제조경비 (627*)
            (3,1,N'제)직원급여'),(3,2,N'제)상여금'),(3,3,N'제)제수당'),(3,4,N'제)퇴직급여'),(3,5,N'제)주식보상비용'),
            (3,6,N'제)급여-사회보험료'),(3,7,N'제)급여-건강보험'),(3,8,N'제)급여-노동자실업보험료'),(3,9,N'제)급여-노동자노조비'),
            (3,10,N'제)급여-개인소득세'),(3,11,N'제)급여-기타'),(3,12,N'제)급여-기타비용'),(3,13,N'제)여비교통비'),
            (3,14,N'제)통신비'),(3,15,N'제)수도광열비'),(3,16,N'제)전력비'),(3,17,N'제)감가상각비'),(3,18,N'제)지급임차료'),
            (3,19,N'제)수선비'),(3,20,N'제)보험료'),(3,21,N'제)차량유지비'),(3,22,N'제)운반비'),(3,23,N'제)교육훈련비'),
            (3,24,N'제)도서인쇄비'),(3,25,N'제)소모품비'),(3,26,N'제)지급수수료'),(3,27,N'제)외주가공비'),(3,28,N'제)사용권자산감가상각비'),
            (3,29,N'제)검사비'),(3,30,N'제)견본비'),(3,31,N'기술지원 및 기술이전비'),
            (3,32,N'제)공구 및 도구 비용 - 상각비용'),(3,33,N'제)공구 및 도구 비용 -일회성비용')
        ) v(sec, seq, item);

        ---------------------------------------------------------------------
        -- 10. 재공 재고 (doi_vn_cost) — BOH/EOH 8포지션 금액합
        ---------------------------------------------------------------------
        SELECT YYYYMM,
               SUM(ISNULL(BOH_LINE_WIP_전_AMT,0)+ISNULL(BOH_LINE_WIP_후_AMT,0)
                  +ISNULL(BOH_LINE_FGS_전_AMT,0)+ISNULL(BOH_LINE_FGS_후_AMT,0)
                  +ISNULL(BOH_B_WIP_전_AMT,0)+ISNULL(BOH_B_WIP_후_AMT,0)
                  +ISNULL(BOH_B_FGS_전_AMT,0)+ISNULL(BOH_B_FGS_후_AMT,0)) AS wip_boh,
               SUM(ISNULL(EOH_LINE_WIP_전_AMT,0)+ISNULL(EOH_LINE_WIP_후_AMT,0)
                  +ISNULL(EOH_LINE_FGS_전_AMT,0)+ISNULL(EOH_LINE_FGS_후_AMT,0)
                  +ISNULL(EOH_B_WIP_전_AMT,0)+ISNULL(EOH_B_WIP_후_AMT,0)
                  +ISNULL(EOH_B_FGS_전_AMT,0)+ISNULL(EOH_B_FGS_후_AMT,0)) AS wip_eoh
        INTO #WIP
        FROM doi_vn_cost WITH(NOLOCK)
        WHERE SITE = @SITE AND SEL_CODE = @SEL_CODE AND LEFT(YYYYMM,4) = @YYYY
        GROUP BY YYYYMM;

        ---------------------------------------------------------------------
        -- 11. 월별 지표 통합 (#M)
        ---------------------------------------------------------------------
        SELECT c.YYYYMM, c.월번호,
               ISNULL(sa.prod_sale,0)  AS prod_sale,
               ISNULL(sa.merch_sale,0) AS merch_sale,
               ISNULL(sa.total_sale,0) AS total_sale,
               ISNULL(sa.qty,0)        AS qty,
               ISNULL(sc.scof,0)       AS scof,
               ISNULL(st.fg_boh,0)     AS fg_boh,
               ISNULL(st.cur_mfg,0)    AS cur_mfg,
               ISNULL(st.fg_eoh,0)     AS fg_eoh,
               ISNULL(st.prod_cogs,0)  AS prod_cogs,
               ISNULL(mc.merch_cogs,0) AS merch_cogs,
               ISNULL(aj.adj,0)        AS adj,
               ISNULL(sg.sgna_tot,0)   AS sgna_tot,
               ISNULL(mt.raw_mat,0)    AS raw_mat,
               ISNULL(mt.sub_mat,0)    AS sub_mat,
               ISNULL(mt.mat_tot,0)    AS mat_tot,
               ISNULL(fb.labor,0)      AS labor,
               ISNULL(fb.expn,0)       AS expn,
               ISNULL(wp.wip_boh,0)    AS wip_boh,
               ISNULL(wp.wip_eoh,0)    AS wip_eoh
        INTO #M
        FROM #CAL c
        LEFT JOIN #SALE  sa ON sa.YYYYMM = c.YYYYMM
        LEFT JOIN #SCOF  sc ON sc.YYYYMM = c.YYYYMM
        LEFT JOIN #STCO  st ON st.YYYYMM = c.YYYYMM
        LEFT JOIN #MCOGS mc ON mc.YYYYMM = c.YYYYMM
        LEFT JOIN #ADJ   aj ON aj.YYYYMM = c.YYYYMM
        LEFT JOIN (SELECT YYYYMM, SUM(amt) AS sgna_tot
                   FROM #SGNA_RAW
                   WHERE ISNULL(상위계정과목,N'') <> N'' AND 상위계정과목 <> N'비용제외'
                   GROUP BY YYYYMM) sg ON sg.YYYYMM = c.YYYYMM
        LEFT JOIN #MAT  mt ON mt.YYYYMM = c.YYYYMM
        LEFT JOIN (SELECT YYYYMM,
                          SUM(CASE WHEN sec = 2 THEN amt ELSE 0 END) AS labor,
                          SUM(CASE WHEN sec = 3 THEN amt ELSE 0 END) AS expn
                   FROM #FABD GROUP BY YYYYMM) fb ON fb.YYYYMM = c.YYYYMM
        LEFT JOIN #WIP  wp ON wp.YYYYMM = c.YYYYMM;

        -- 연간 스칼라(비율행 tot 용)
        DECLARE @AnnSale float, @AnnGP float, @AnnOP float;
        SELECT @AnnSale = SUM(total_sale - scof),
               @AnnGP   = SUM((total_sale - scof) - (prod_cogs + adj + merch_cogs)),
               @AnnOP   = SUM((total_sale - scof) - (prod_cogs + adj + merch_cogs) - sgna_tot)
        FROM #M;

        ---------------------------------------------------------------------
        -- 12. Long 셋 (순서, 구분, 월번호, 금액)  — 순서는 ×100 스킴(헤더+세목 seq)
        ---------------------------------------------------------------------
        CREATE TABLE #LONG (순서 int, 구분 nvarchar(200), 월번호 int, 금액 decimal(18,2));

        INSERT INTO #LONG (순서, 구분, 월번호, 금액)
        -- 매출
        SELECT  100, N'매출액',                 월번호, CAST(total_sale - scof AS decimal(18,2)) FROM #M
        UNION ALL SELECT  200, N'  (1) 제품매출', 월번호, CAST(prod_sale AS decimal(18,2)) FROM #M
        UNION ALL SELECT  300, N'  (2) 유상사급', 월번호, CAST(scof AS decimal(18,2)) FROM #M
        UNION ALL SELECT  400, N'  (3) 상품매출', 월번호, CAST(merch_sale AS decimal(18,2)) FROM #M
        UNION ALL SELECT  500, N'  수량(Cell)',   월번호, CAST(qty AS decimal(18,2)) FROM #M
        -- 매출원가
        UNION ALL SELECT  600, N'매출원가',               월번호, CAST(prod_cogs + adj + merch_cogs AS decimal(18,2)) FROM #M
        UNION ALL SELECT  700, N'  (1) 제품매출원가',     월번호, CAST(prod_cogs + adj AS decimal(18,2)) FROM #M
        UNION ALL SELECT  800, N'  (2) 상품매출원가',     월번호, CAST(merch_cogs AS decimal(18,2)) FROM #M
        UNION ALL SELECT  900, N'  (3) 제품매출원가조정', 월번호, CAST(adj AS decimal(18,2)) FROM #M
        UNION ALL SELECT 1000, N'  기초제품재고액',       월번호, CAST(fg_boh AS decimal(18,2)) FROM #M
        UNION ALL SELECT 1100, N'  당기제품제조원가',     월번호, CAST(cur_mfg AS decimal(18,2)) FROM #M
        UNION ALL SELECT 1200, N'  기말제품재고액',       월번호, CAST(fg_eoh AS decimal(18,2)) FROM #M
        -- 제조원가 내역 : 재료비
        UNION ALL SELECT 1300, N'재료비',     월번호, CAST(mat_tot AS decimal(18,2)) FROM #M
        UNION ALL SELECT 1310, N'  원재료비', 월번호, CAST(raw_mat AS decimal(18,2)) FROM #M
        UNION ALL SELECT 1320, N'  부재료비', 월번호, CAST(sub_mat AS decimal(18,2)) FROM #M
        -- 직접노무비 (헤더 = 세목합)
        UNION ALL SELECT 1400, N'직접노무비', 월번호, CAST(labor AS decimal(18,2)) FROM #M
        UNION ALL
        SELECT 1400 + sk.seq, N'  (' + CAST(sk.seq AS varchar(2)) + N') ' + sk.item, c.월번호,
               CAST(ISNULL(d.amt,0) AS decimal(18,2))
        FROM #CAL c
        CROSS JOIN (SELECT seq, item FROM #MSK WHERE sec = 2) sk
        LEFT JOIN #FABD d ON d.YYYYMM = c.YYYYMM AND d.sec = 2 AND d.item = sk.item
        -- 간접제조경비 (헤더 = 세목합)
        UNION ALL SELECT 1500, N'간접제조경비', 월번호, CAST(expn AS decimal(18,2)) FROM #M
        UNION ALL
        SELECT 1500 + sk.seq, N'  (' + CAST(sk.seq AS varchar(2)) + N') ' + sk.item, c.월번호,
               CAST(ISNULL(d.amt,0) AS decimal(18,2))
        FROM #CAL c
        CROSS JOIN (SELECT seq, item FROM #MSK WHERE sec = 3) sk
        LEFT JOIN #FABD d ON d.YYYYMM = c.YYYYMM AND d.sec = 3 AND d.item = sk.item
        -- 당기총제조원가 = 재료비 + 직접노무비 + 간접제조경비
        UNION ALL SELECT 1600, N'당기총제조원가',   월번호, CAST(mat_tot + labor + expn AS decimal(18,2)) FROM #M
        UNION ALL SELECT 1610, N'  기초재공재고액', 월번호, CAST(wip_boh AS decimal(18,2)) FROM #M
        UNION ALL SELECT 1620, N'  기말재공재고액', 월번호, CAST(wip_eoh AS decimal(18,2)) FROM #M
        -- 이익
        UNION ALL SELECT 1700, N'매출총이익',     월번호,
                  CAST((total_sale - scof) - (prod_cogs + adj + merch_cogs) AS decimal(18,2)) FROM #M
        UNION ALL SELECT 1800, N'(매출총이익률)', 월번호,
                  CAST(CASE WHEN (total_sale - scof) = 0 THEN 0
                            ELSE ((total_sale - scof) - (prod_cogs + adj + merch_cogs)) / NULLIF(total_sale - scof,0) * 100 END AS decimal(18,2)) FROM #M
        -- 판매관리비
        UNION ALL SELECT 1900, N'판매비와관리비', 월번호, CAST(sgna_tot AS decimal(18,2)) FROM #M
        UNION ALL
        SELECT 1900 + sk.seq, N'  (' + CAST(sk.seq AS varchar(2)) + N') ' + sk.item, c.월번호,
               CAST(ISNULL(d.amt,0) AS decimal(18,2))
        FROM #CAL c
        CROSS JOIN #SGSK sk
        LEFT JOIN (SELECT YYYYMM, item, SUM(amt) AS amt
                   FROM #SGNA_RAW WHERE item <> N'' GROUP BY YYYYMM, item) d
               ON d.YYYYMM = c.YYYYMM AND d.item = sk.item
        -- 영업이익
        UNION ALL SELECT 2000, N'영업이익',     월번호,
                  CAST((total_sale - scof) - (prod_cogs + adj + merch_cogs) - sgna_tot AS decimal(18,2)) FROM #M
        UNION ALL SELECT 2100, N'(영업이익률)', 월번호,
                  CAST(CASE WHEN (total_sale - scof) = 0 THEN 0
                            ELSE ((total_sale - scof) - (prod_cogs + adj + merch_cogs) - sgna_tot) / NULLIF(total_sale - scof,0) * 100 END AS decimal(18,2)) FROM #M;

        ---------------------------------------------------------------------
        -- 13. 피벗 (구분 × tot × 1월~12월)
        --      비율행(순서 1800/2100) tot = 연간율, 그 외 tot = 12개월 합
        ---------------------------------------------------------------------
        SELECT
            구분,
            CASE WHEN 순서 = 1800 THEN CAST(CASE WHEN ISNULL(@AnnSale,0)=0 THEN 0 ELSE @AnnGP/@AnnSale*100 END AS decimal(18,2))
                 WHEN 순서 = 2100 THEN CAST(CASE WHEN ISNULL(@AnnSale,0)=0 THEN 0 ELSE @AnnOP/@AnnSale*100 END AS decimal(18,2))
                 ELSE ISNULL([1월],0)+ISNULL([2월],0)+ISNULL([3월],0)+ISNULL([4월],0)+ISNULL([5월],0)+ISNULL([6월],0)
                     +ISNULL([7월],0)+ISNULL([8월],0)+ISNULL([9월],0)+ISNULL([10월],0)+ISNULL([11월],0)+ISNULL([12월],0)
            END AS tot,
            ISNULL([1월],0) AS [1월],   ISNULL([2월],0) AS [2월],   ISNULL([3월],0) AS [3월],
            ISNULL([4월],0) AS [4월],   ISNULL([5월],0) AS [5월],   ISNULL([6월],0) AS [6월],
            ISNULL([7월],0) AS [7월],   ISNULL([8월],0) AS [8월],   ISNULL([9월],0) AS [9월],
            ISNULL([10월],0) AS [10월], ISNULL([11월],0) AS [11월], ISNULL([12월],0) AS [12월]
        FROM (
            SELECT 순서, 구분, CAST(월번호 AS varchar(2)) + N'월' AS 월, 금액 FROM #LONG
        ) src
        PIVOT (
            SUM(금액) FOR 월 IN ([1월],[2월],[3월],[4월],[5월],[6월],[7월],[8월],[9월],[10월],[11월],[12월])
        ) p
        ORDER BY 순서;

        DROP TABLE #CAL, #MERCH, #SALE, #SCOF, #MCOGS, #STCO, #ADJ,
                   #SGNA_RAW, #SGSK, #MAT, #FABD, #MSK, #WIP, #M, #LONG;
    END TRY
    BEGIN CATCH
        SELECT ERROR_MESSAGE() AS ErrorMessage;
    END CATCH;
END;
