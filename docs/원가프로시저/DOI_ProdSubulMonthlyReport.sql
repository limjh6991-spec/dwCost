CREATE             PROCEDURE DOI_ProdSubulMonthlyReport
(
    @YYYY VARCHAR(4),
    @SITE VARCHAR(4)   -- HQ / VN
)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        ------------------------------------------------------------
        -- 1) 연도 기준 YYYYMM 생성 (1~12월)
        ------------------------------------------------------------
        ;WITH GEN_YYYYMM AS (
            SELECT
                  CAST(@YYYY + '0101' AS DATE) AS DT
                , FORMAT(CAST(@YYYY + '0101' AS DATE), 'yyyyMM') AS YYYYMM
                , 1 AS 월번호
            UNION ALL
            SELECT
                  DATEADD(MONTH, 1, DT)
                , FORMAT(DATEADD(MONTH, 1, DT), 'yyyyMM')
                , MONTH(DATEADD(MONTH, 1, DT))
            FROM GEN_YYYYMM
            WHERE DT < CAST(@YYYY + '1201' AS DATE)
        )
        SELECT *
        INTO #GEN_YYYYMM
        FROM GEN_YYYYMM
        OPTION (MAXRECURSION 12);


        ------------------------------------------------------------
        -- 2) 원천 정리 (Adj_YN='Y'만)
        ------------------------------------------------------------
        ;WITH BASE AS (
            SELECT *
            FROM (
                SELECT
                      v.*
                    , ROW_NUMBER() OVER (
                        PARTITION BY v.YYYYMM, v.SITE, v.도우모델, v.Inch, v.DW_Site
                        ORDER BY CASE WHEN v.Adj_YN = 'Y' THEN 1 ELSE 0 END DESC
                      ) AS rn
                FROM V_DOI_PROD_SUBUL v WITH (NOLOCK)
                WHERE SUBSTRING(v.YYYYMM, 1, 4) = @YYYY
                  AND v.SITE = @SITE --AND 도우모델='0226'
                 -- AND BOH_MONTH+IN_MONTH+BONUS_MONTH+EOH_MONTH+OUT_MONTH+LOSS_MONTH+NG_MONTH+수율제외_MONTH+REWORK진행_MONTH+SHIPPING_PLAN_MONTH+SHIPPING_ACTUAL_MONTH+material_loss+recall_loss != 0
            ) t
            --WHERE t.rn = 1
        )
        SELECT *
        INTO #BASE
        FROM BASE
        UNION ALL
		select
			YYYYMM,
			'ACTUAL' SEL_CODE,
			SITE,
			구분,
			1 구분_ord,
			품명,
			품번,
			'-' 작업구분,
			'-' org작업구분,
			'-' model,
			'-' Inch,
			'VINA' DW_Site,
			0 BOH_MONTH,
			수량 IN_MONTH,
			0 BONUS_MONTH,
			0 EOH_MONTH,
			수량 OUT_MONTH,
			0 LOSS_MONTH,
			0 NG_MONTH,
			0 수율제외_MONTH,
			0 REWORK진행_MONTH,
			0 SHIPPING_PLAN_MONTH,
			0 SHIPPING_ACTUAL_MONTH,
			0 material_loss,
			0 recall_loss,
			'Y' Adj_YN,
			1 rn,
			0 OUTETC_MONTH
		from
			doi_sale
		WHERE
			SUBSTRING(YYYYMM, 1, 4) = @YYYY
			and 구분 = '카세트';


        ------------------------------------------------------------
        -- 3) 도우모델 기준 목록 (도우모델 + Inch + DW_Site)
        ------------------------------------------------------------
        ;WITH CODE_BASE AS (
            SELECT DISTINCT
				 구분
                , 도우모델 AS 모델
                , MAX(Inch) AS Inch
                , MAX(DW_Site) AS DW_Site
            FROM #BASE
            GROUP BY  구분,도우모델
        )
        SELECT *
        INTO #CODE_BASE
        FROM CODE_BASE;


        ------------------------------------------------------------
        -- 4) 월별 수량 집계 (#AGG)
        --    계획: 현재 알 수 없으므로 NULL로 처리 (최종 SELECT에서 그대로 NULL)
        --    산식:
        --      불량률 = LOSS/(OUT+LOSS)
        --      수율   = OUT /(OUT+LOSS)
        ------------------------------------------------------------
        ;WITH AGG AS (
            SELECT
                  b.YYYYMM
                , b.SITE
                , MAX(MAX(b.DW_Site)) over (PARTITION BY b.도우모델) as DW_Site
                , MAX(MAX(b.Inch))  over (PARTITION BY b.도우모델)AS Inch
                , b.도우모델 AS 모델
				, 구분

                , SUM(ISNULL(b.BOH_MONTH, 0))  AS BOH
                , SUM(ISNULL(b.IN_MONTH, 0))   AS [IN]
                , SUM(ISNULL(b.OUT_MONTH, 0))  AS [OUT]
                , SUM(ISNULL(b.LOSS_MONTH, 0)) AS LOSS
                , SUM(ISNULL(b.EOH_MONTH, 0))  AS EOH
                , SUM(ISNULL(b.OUTETC_MONTH, 0))  AS OUTETC

                -- 필요하면 추가 수량들도 같이 내보낼 수 있게 미리 집계해둠
                , SUM(ISNULL(b.NG_MONTH, 0))           AS NG
                , SUM(ISNULL(b.수율제외_MONTH, 0))     AS 수율제외
                , SUM(ISNULL(b.REWORK진행_MONTH, 0))   AS REWORK진행
                , SUM(ISNULL(b.BONUS_MONTH, 0))        AS BONUS
                , SUM(ISNULL(b.material_loss, 0))      AS material_loss
                , SUM(ISNULL(b.recall_loss, 0))        AS recall_loss
                , SUM(ISNULL(b.SHIPPING_PLAN_MONTH,0)) AS SHIPPING_PLAN   -- 참고용(현재 사용 안함)
                , SUM(ISNULL(b.SHIPPING_ACTUAL_MONTH,0)) AS SHIPPING_ACTUAL -- 참고용(현재 사용 안함)
            FROM #BASE b
            GROUP BY b.YYYYMM, b.SITE, b.DW_Site, b.Inch, b.도우모델, b.구분
        )
        SELECT *
        INTO #AGG
        FROM AGG;


        ------------------------------------------------------------
        -- 5) 최종 출력
        --    - 전체합계 1행 ("당월 총 생산실적" = 연도 전체 총합)
        --    - 도우모델별 1~12월 세로 출력(빈 달 0)
        ------------------------------------------------------------

        -- (A) 도우모델별 월행 (1~12월 무조건)
		;WITH DETAIL AS (
		    SELECT
		          cb.구분
		        , cb.모델
		        , cb.Inch
		        , cb.DW_Site
		        , g.월번호
		        , CAST(g.월번호 AS varchar(2)) + N'월' AS 월
		
		        , CAST(NULL AS decimal(18,2)) AS 계획
				, COALESCE(a.[OUT], 0)    AS 실적
				, CASE 
				    WHEN COALESCE(CAST(NULL AS decimal(18,2)),0) = 0 THEN 0
				    ELSE COALESCE(a.[OUT],0) * 1.0 / CAST(NULL AS decimal(18,2))
				  END AS 달성률
		
		        , COALESCE(a.BOH, 0)  AS BOH
		        , COALESCE(a.[IN], 0) AS [IN]
		        , COALESCE(a.[OUT], 0)  AS [OUT]
		        , COALESCE(a.LOSS, 0) AS LOSS
		        , COALESCE(a.EOH, 0)  AS EOH
		        , COALESCE(a.OUTETC, 0)  AS OUTETC
		
		        -- 불량률 = LOSS/(OUT+LOSS), 수율 = OUT/(OUT+LOSS)
		        , CASE WHEN (COALESCE(a.[OUT],0) + COALESCE(a.LOSS,0)) = 0 THEN 0
		               ELSE CAST(a.LOSS AS decimal(18,6))
		                    / NULLIF(COALESCE(a.[OUT],0) + COALESCE(a.LOSS,0), 0) END AS 불량률
		        , CASE WHEN (COALESCE(a.[OUT],0) + COALESCE(a.LOSS,0)) = 0 THEN 0
		               ELSE CAST(a.[OUT] AS decimal(18,6))
		                    / NULLIF(COALESCE(a.[OUT],0) + COALESCE(a.LOSS,0), 0) END AS 수율
		
		        , COALESCE(a.NG,0) AS NG
		        , COALESCE(a.수율제외,0) AS 수율제외
		        , COALESCE(a.REWORK진행,0) AS REWORK진행
		        , COALESCE(a.BONUS,0) AS BONUS
		        , COALESCE(a.material_loss,0) AS material_loss
		        , COALESCE(a.recall_loss,0) AS recall_loss
		    FROM #CODE_BASE cb
		    CROSS JOIN #GEN_YYYYMM g
		    RIGHT JOIN #AGG a
		           ON a.YYYYMM  = g.YYYYMM
	          	  AND a.SITE    =	@SITE
		          AND a.구분    = cb.구분
		          AND a.모델    = cb.모델
		          /*AND a.Inch    = cb.Inch
		          AND a.DW_Site = cb.DW_Site*/
		),
		TOTAL AS (
		    SELECT
		          N'당월 총 생산실적' AS 구분
		        , N''     AS 모델
		        , CAST(NULL AS varchar(30)) AS Inch
		        , CAST(NULL AS varchar(30)) AS DW_Site
		        , 0 AS 월번호
		        , N'당월 총 생산실적' AS 월
		
				, CAST(NULL AS decimal(18,2)) AS 계획
				, SUM([OUT])                  AS 실적
				, CASE 
				    WHEN SUM([OUT]) = 0 THEN 0
				    ELSE 1.0
				  END AS 달성률
						
		        , SUM(BOH) AS BOH
		        , SUM([IN])  AS [IN]
		        , SUM([OUT]) AS [OUT]
		        , SUM(LOSS) AS LOSS
		        , SUM(EOH) AS EOH
		        , SUM(OUTETC) AS OUT_ETC
		
		        , CASE WHEN (SUM([OUT]) + SUM(LOSS)) = 0 THEN 0
		               ELSE CAST(SUM(LOSS) AS decimal(18,6))
		                    / NULLIF(SUM([OUT]) + SUM(LOSS), 0) END AS 불량률
		        , CASE WHEN (SUM([OUT]) + SUM(LOSS)) = 0 THEN 0
		               ELSE CAST(SUM([OUT]) AS decimal(18,6))
		                    / NULLIF(SUM([OUT]) + SUM(LOSS), 0) END AS 수율
		
		        , SUM(NG) AS NG
		        , SUM(수율제외) AS 수율제외
		        , SUM(REWORK진행) AS REWORK진행
		        , SUM(BONUS) AS BONUS
		        , SUM(material_loss) AS material_loss
		        , SUM(recall_loss) AS recall_loss
		    FROM DETAIL
		)
		SELECT
		      t.구분
		    , t.모델
		    , t.Inch
		    , t.DW_Site
		   , t.월
		    , t.계획
		    , t.실적
		    , t.달성률
		    , t.BOH
		    , t.[IN]
		    , t.[OUT]
		    , t.LOSS
		    , t.EOH
		    , t.OUT_ETC
		    , t.불량률
		    , t.수율
		    -- 필요하면 “전체 수량”도 같이
		    --, t.NG, t.수율제외, t.REWORK진행, t.BONUS, t.material_loss, t.recall_loss
		FROM (
		    SELECT * FROM TOTAL
		    UNION ALL
		    SELECT * FROM DETAIL
		) t
		ORDER BY
		    t.구분 DESC, t.모델, t.Inch, t.dw_site, t.월번호;

        ------------------------------------------------------------
        -- 6) 임시테이블 삭제
        ------------------------------------------------------------
        DROP TABLE #GEN_YYYYMM;
        DROP TABLE #BASE;
        DROP TABLE #CODE_BASE;
        DROP TABLE #AGG;

    END TRY
    BEGIN CATCH
        SELECT ERROR_MESSAGE() AS ErrorMessage;
    END CATCH
END;

