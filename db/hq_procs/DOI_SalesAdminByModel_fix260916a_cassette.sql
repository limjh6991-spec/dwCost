/* ============================================================
   DOI_SalesAdminByModel fix260916a — 판매관리비집계표(제품별) 카세트 대분류 신설
   근거: 「KR 로직 문의 (2).xlsx」 확인요청 6번 / 시트 '6.판매관리비집계표'
         변경 전 : 양산 합계 + 개발 합계 + 양산열 + 개발열
         변경 후 : 양산 합계 + 개발 합계 + 카세트 합계(W합계) + 양산열 + 개발열 + 카세트열
   방식: PIVOT 키 구분 = LEFT(model,2)='VN' → N'카세트' + W합계(카세트 합계) 행 추가.
         리포트 전용 SELECT, 재결산 불필요. 화면은 jar 재빌드 필요(W합계 열).

   기준: 운영 정의(2026-02-18 12:52:07)와 src/sql/원가프로시저/DOI_SalesAdminByModel_xx.sql 이
         프로시저명 줄만 빼고 완전히 동일함을 2026-09-16 확인(275줄, diff 1줄). 그 위에 얹었다.
         ※ 저장소의 DOI_SalesAdminByModel.sql(_xx 없는 쪽)은 구버전이니 쓰지 말 것.

   검증(2026-09-16, 202608 HQ ACTUAL, 애드혹 읽기전용 실행):
         W합계 열 1개만 추가(값 0), 기존 30개 열 값 변화 0건.
         양산 1,057,837,624 / 개발 205,124,808 그대로 — 엑셀 변경 후와 일치.
         카세트 모델열은 doi_smce_cost 에 VN 모델 행이 없어 생기지 않는다(배부되면 자동 생성).
   ============================================================ */
/* 기준 확인 — 운영 정의가 X합계/구분+model 형태인지 검사한다(이미 적용했으면 여기서 멈춘다). */
IF NOT EXISTS (
    SELECT 1
    FROM sys.sql_modules m
    JOIN sys.procedures  p ON p.object_id = m.object_id
    WHERE p.name = 'DOI_SalesAdminByModel'
      AND CHARINDEX(N'X합계', m.definition) > 0
      AND CHARINDEX(N'구분+model', m.definition) > 0
)
BEGIN
    RAISERROR(N'DOI_SalesAdminByModel 운영 정의가 기준(X합계 / 구분+model)과 다릅니다. 이미 fix260916a 를 적용했거나 운영 정의가 바뀐 것입니다.', 16, 1);
    SET NOEXEC ON;
END
GO
-- [2026-09-16a] 카세트 대분류 신설 (판매관리비집계표 제품별)
ALTER PROCEDURE DOI_SalesAdminByModel(
    @YYYYMM varchar(10),
     @SITE varchar(4),
     @SEL_CODE varchar(10)
)
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
        DECLARE @Columns VARCHAR(3000);
        DECLARE @Null_Columns VARCHAR(3000);
        DECLARE @SQL NVARCHAR(MAX);
		DECLARE @Prod_Rate DECIMAL(18,2) = 0;
		DECLARE @Dev_Rate DECIMAL(18,2)  = 0;
		DECLARE @Cas_Rate DECIMAL(18,2)  = 0;   -- [2026-09-16a] 카세트 배부율

        SELECT @Columns = COALESCE(@Columns + '], [', '') + model
        FROM (SELECT DISTINCT TOP 500 model 
                FROM (
                SELECT DISTINCT CASE WHEN LEFT(model,2) = N'VN' THEN N'카세트' ELSE 구분 END+model as model from doi_smce_cost where yyyymm=@YYYYMM and site=@SITE and sel_code=@SEL_CODE
                union all SELECT 'X합계' model union all SELECT 'Y합계' model union all SELECT 'W합계' model union all SELECT 'Z합계' model
                  )A
                ORDER BY 1 )AS 도우모델 ;
        
        select @Columns=  '['+@Columns+']';
        
        SELECT @Null_Columns = COALESCE(@Null_Columns, '') + MODEL +'],0) as ['+MODEL+'],coalesce([' 
        FROM (SELECT DISTINCT TOP 500 model 
                FROM (
                SELECT DISTINCT CASE WHEN LEFT(model,2) = N'VN' THEN N'카세트' ELSE 구분 END+model as model from doi_smce_cost where yyyymm=@YYYYMM and site=@SITE and sel_code=@SEL_CODE
                union all SELECT 'X합계' model union all SELECT 'Y합계' model union all SELECT 'W합계' model union all SELECT 'Z합계' mode
                  )A
                ORDER BY 1 )AS 도우모델 ;
        
        select @Null_Columns=  'rn,gubun,'+ replace('coalesce(['+@Null_Columns+']',',coalesce([]','');

        with sourceTable as (
            select X.*, COALESCE(Y.amt,0) amt from (
                select * from (
                    SELECT DISTINCT TOP 500 model 
                    FROM (
                        SELECT DISTINCT CASE WHEN LEFT(model,2) = N'VN' THEN N'카세트' ELSE 구분 END+model as model from doi_smce_cost where yyyymm=@YYYYMM and site=@SITE and sel_code=@SEL_CODE
                    )A
                    ORDER BY 1
                ) A 
                cross join 
                (
                select 0 as rn, '    판관비 배부율 (제품별 매출비중)' as gubun
                union all select 1, '    (1) 판)임원급여'
                union all select 3, '    (2) 판)직원급여'
                union all select 5, '    (3) 판)상여금'
                union all select 7, '    (4) 판)제수당'
                union all select 10, '    (5) 판)퇴직급여'
                union all select 13, '    (6) 판)복리후생비'
                union all select 20, '    (7) 판)여비교통비'
                union all select 25, '    (8) 판)접대비'
                union all select 29, '    (9) 판)통신비'
                union all select 31, '    (10) 판)수도광열비'
                union all select 33, '    (11) 판)세금과공과'
                union all select 38, '    (12) 판)감가상각비'
                union all select 44, '    (13) 판)지급임차료'
                union all select 49, '    (14) 판)수선비'
                union all select 51, '    (15) 판)보험료'
                union all select 56, '    (16) 판)차량유지비'
                union all select 61, '    (17) 판)경상연구개발비'
                union all select 92, '    (18) 판)운반비'
                union all select 95, '    (19) 판)교육훈련비'
                union all select 97, '    (20) 판)도서인쇄비'
                union all select 99, '    (21) 판)소모품비'
                union all select 104, '    (22) 판)지급수수료'
                union all select 112, '    (23) 판)광고선전비'
                union all select 115, '    (24) 판)무형자산상각비'
                union all select 117, '    (25) 판)견본비'
                union all select 119, '    (26) 판)사용권자산감가상각비'
                union all select 122, '    (27) 판)주식보상비용'
                union all select 124, '    (28) 판)해외시장개척비'
                union all select 999, '    (29) 합계'
                ) B 
            ) X 
            left join (
            select 0 as rn, '    판관비 배부율 (제품별 매출비중)'as gubun, model, cast(amt/sum(amt) over() as numeric(10,3)) as amt
            from (
                select CASE WHEN LEFT(model,2) = N'VN' THEN N'카세트' ELSE 구분 END+model as model, sum(dist_amt) as amt
                from doi_smce_cost
                where yyyymm = @yyyymm and site =  @site and sel_code=@SEL_CODE
                group by CASE WHEN LEFT(model,2) = N'VN' THEN N'카세트' ELSE 구분 END+model
            ) A
            union all
            select 1 as rn, '    (1) 판)임원급여' as gubun, CASE WHEN LEFT(model,2) = N'VN' THEN N'카세트' ELSE 구분 END+model as model, sum(dist_amt) as amt
            from doi_smce_cost
            where yyyymm = @yyyymm and site = @site and sub_name = '판)급여-임원' and sel_code=@SEL_CODE
            group by CASE WHEN LEFT(model,2) = N'VN' THEN N'카세트' ELSE 구분 END+model
            union all
            select 3 as rn, '    (2) 판)직원급여' as gubun, CASE WHEN LEFT(model,2) = N'VN' THEN N'카세트' ELSE 구분 END+model as model, sum(dist_amt) as amt
            from doi_smce_cost
            where yyyymm = @yyyymm and site = @site and sub_name = '판)급여-직원' and sel_code=@SEL_CODE
            group by CASE WHEN LEFT(model,2) = N'VN' THEN N'카세트' ELSE 구분 END+model
            union all
            select 5 as rn, '    (3) 판)상여금' as gubun, CASE WHEN LEFT(model,2) = N'VN' THEN N'카세트' ELSE 구분 END+model as model, sum(dist_amt) as amt
            from doi_smce_cost
            where yyyymm = @yyyymm and site = @site and sub_name = '판)상여금-직원' and sel_code=@SEL_CODE
            group by CASE WHEN LEFT(model,2) = N'VN' THEN N'카세트' ELSE 구분 END+model
            union all
            select 7 as rn, '    (4) 판)제수당' as gubun, CASE WHEN LEFT(model,2) = N'VN' THEN N'카세트' ELSE 구분 END+model as model, sum(dist_amt) as amt
            from doi_smce_cost
            where yyyymm = @yyyymm and site = @site and sub_name like '판)제수당%' and sel_code=@SEL_CODE
            group by CASE WHEN LEFT(model,2) = N'VN' THEN N'카세트' ELSE 구분 END+model
            union all
            select 10 as rn, '    (5) 판)퇴직급여' as gubun, CASE WHEN LEFT(model,2) = N'VN' THEN N'카세트' ELSE 구분 END+model as model, sum(dist_amt) as amt
            from doi_smce_cost
            where yyyymm = @yyyymm and site = @site and sub_name like '판)퇴직급여%' and sel_code=@SEL_CODE
            group by CASE WHEN LEFT(model,2) = N'VN' THEN N'카세트' ELSE 구분 END+model
            union all
            select 13 as rn, '    (6) 판)복리후생비' as gubun, CASE WHEN LEFT(model,2) = N'VN' THEN N'카세트' ELSE 구분 END+model as model, sum(dist_amt) as amt
            from doi_smce_cost
            where yyyymm = @yyyymm and site = @site and sub_name like '판)복리후생비%' and sel_code=@SEL_CODE
            group by CASE WHEN LEFT(model,2) = N'VN' THEN N'카세트' ELSE 구분 END+model
            union all
            select 20 as rn, '    (7) 판)여비교통비' as gubun, CASE WHEN LEFT(model,2) = N'VN' THEN N'카세트' ELSE 구분 END+model as model, sum(dist_amt) as amt
            from doi_smce_cost
            where yyyymm = @yyyymm and site = @site and sub_name like '판)여비교통비%' and sel_code=@SEL_CODE
            group by CASE WHEN LEFT(model,2) = N'VN' THEN N'카세트' ELSE 구분 END+model
            union all
            select 25 as rn, '    (8) 판)접대비' as gubun, CASE WHEN LEFT(model,2) = N'VN' THEN N'카세트' ELSE 구분 END+model as model, sum(dist_amt) as amt
            from doi_smce_cost
            where yyyymm = @yyyymm and site = @site and sub_name like '판)접대비%' and sel_code=@SEL_CODE
            group by CASE WHEN LEFT(model,2) = N'VN' THEN N'카세트' ELSE 구분 END+model
            union all
            select 29 as rn, '    (9) 판)통신비' as gubun, CASE WHEN LEFT(model,2) = N'VN' THEN N'카세트' ELSE 구분 END+model as model, sum(dist_amt) as amt
            from doi_smce_cost
            where yyyymm = @yyyymm and site = @site and sub_name like '판)통신비%' and sel_code=@SEL_CODE
            group by CASE WHEN LEFT(model,2) = N'VN' THEN N'카세트' ELSE 구분 END+model
            union all
            select 31 as rn, '    (10) 판)수도광열비' as gubun, CASE WHEN LEFT(model,2) = N'VN' THEN N'카세트' ELSE 구분 END+model as model, sum(dist_amt) as amt
            from doi_smce_cost
            where yyyymm = @yyyymm and site = @site and sub_name like '판)수도광열비%' and sel_code=@SEL_CODE
            group by CASE WHEN LEFT(model,2) = N'VN' THEN N'카세트' ELSE 구분 END+model
            union all
            select 33 as rn, '    (11) 판)세금과공과' as gubun, CASE WHEN LEFT(model,2) = N'VN' THEN N'카세트' ELSE 구분 END+model as model, sum(dist_amt) as amt
            from doi_smce_cost
            where yyyymm = @yyyymm and site = @site and sub_name like '판)세금과공과%' and sel_code=@SEL_CODE
            group by CASE WHEN LEFT(model,2) = N'VN' THEN N'카세트' ELSE 구분 END+model
            union all
            select 38 as rn, '    (12) 판)감가상각비' as gubun, CASE WHEN LEFT(model,2) = N'VN' THEN N'카세트' ELSE 구분 END+model as model, sum(dist_amt) as amt
            from doi_smce_cost
            where yyyymm = @yyyymm and site = @site and sub_name like '판)감가상각비%' and sel_code=@SEL_CODE
            group by CASE WHEN LEFT(model,2) = N'VN' THEN N'카세트' ELSE 구분 END+model
            union all
            select 44 as rn, '    (13) 판)지급임차료' as gubun, CASE WHEN LEFT(model,2) = N'VN' THEN N'카세트' ELSE 구분 END+model as model, sum(dist_amt) as amt
            from doi_smce_cost
            where yyyymm = @yyyymm and site = @site and sub_name like '판)지급임차료%' and sel_code=@SEL_CODE
            group by CASE WHEN LEFT(model,2) = N'VN' THEN N'카세트' ELSE 구분 END+model
            union all
            select 49 as rn, '    (14) 판)수선비' as gubun, CASE WHEN LEFT(model,2) = N'VN' THEN N'카세트' ELSE 구분 END+model as model, sum(dist_amt) as amt
            from doi_smce_cost
            where yyyymm = @yyyymm and site = @site and sub_name like '판)수선비%' and sel_code=@SEL_CODE
            group by CASE WHEN LEFT(model,2) = N'VN' THEN N'카세트' ELSE 구분 END+model
            union all
            select 51 as rn, '    (15) 판)보험료' as gubun, CASE WHEN LEFT(model,2) = N'VN' THEN N'카세트' ELSE 구분 END+model as model, sum(dist_amt) as amt
            from doi_smce_cost
            where yyyymm = @yyyymm and site = @site and sub_name like '판)보험료%' and sel_code=@SEL_CODE
            group by CASE WHEN LEFT(model,2) = N'VN' THEN N'카세트' ELSE 구분 END+model
            union all
            select 56 as rn, '    (16) 판)차량유지비' as gubun, CASE WHEN LEFT(model,2) = N'VN' THEN N'카세트' ELSE 구분 END+model as model, sum(dist_amt) as amt
            from doi_smce_cost
            where yyyymm = @yyyymm and site = @site and sub_name like '판)차량유지비%' and sel_code=@SEL_CODE
            group by CASE WHEN LEFT(model,2) = N'VN' THEN N'카세트' ELSE 구분 END+model
            union all
            select 61 as rn, '    (17) 판)경상연구개발비' as gubun, CASE WHEN LEFT(model,2) = N'VN' THEN N'카세트' ELSE 구분 END+model as model, sum(dist_amt) as amt
            from doi_smce_cost
            where yyyymm = @yyyymm and site = @site and sub_name like '판)경상연구개발비%' and sel_code=@SEL_CODE
            group by CASE WHEN LEFT(model,2) = N'VN' THEN N'카세트' ELSE 구분 END+model
            union all
            select 92 as rn, '    (18) 판)운반비' as gubun, CASE WHEN LEFT(model,2) = N'VN' THEN N'카세트' ELSE 구분 END+model as model, sum(dist_amt) as amt
            from doi_smce_cost
            where yyyymm = @yyyymm and site = @site and sub_name like '판)운반비%' and sel_code=@SEL_CODE
            group by CASE WHEN LEFT(model,2) = N'VN' THEN N'카세트' ELSE 구분 END+model
            union all
            select 95 as rn, '    (19) 판)교육훈련비' as gubun, CASE WHEN LEFT(model,2) = N'VN' THEN N'카세트' ELSE 구분 END+model as model, sum(dist_amt) as amt
            from doi_smce_cost
            where yyyymm = @yyyymm and site = @site and sub_name like '판)교육훈련비%' and sel_code=@SEL_CODE
            group by CASE WHEN LEFT(model,2) = N'VN' THEN N'카세트' ELSE 구분 END+model
            union all
            select 97 as rn, '    (20) 판)도서인쇄비' as gubun, CASE WHEN LEFT(model,2) = N'VN' THEN N'카세트' ELSE 구분 END+model as model, sum(dist_amt) as amt
            from doi_smce_cost
            where yyyymm = @yyyymm and site = @site and sub_name like '판)도서인쇄비%' and sel_code=@SEL_CODE
            group by CASE WHEN LEFT(model,2) = N'VN' THEN N'카세트' ELSE 구분 END+model
            union all
            select 99 as rn, '    (21) 판)소모품비' as gubun, CASE WHEN LEFT(model,2) = N'VN' THEN N'카세트' ELSE 구분 END+model as model, sum(dist_amt) as amt
            from doi_smce_cost
            where yyyymm = @yyyymm and site = @site and sub_name like '판)소모품비%' and sel_code=@SEL_CODE
            group by CASE WHEN LEFT(model,2) = N'VN' THEN N'카세트' ELSE 구분 END+model
            union all
            select 104 as rn, '    (22) 판)지급수수료' as gubun, CASE WHEN LEFT(model,2) = N'VN' THEN N'카세트' ELSE 구분 END+model as model, sum(dist_amt) as amt
            from doi_smce_cost
            where yyyymm = @yyyymm and site = @site and sub_name like '판)지급수수료%' and sel_code=@SEL_CODE
            group by CASE WHEN LEFT(model,2) = N'VN' THEN N'카세트' ELSE 구분 END+model
            union all
            select 112 as rn, '    (23) 판)광고선전비' as gubun, CASE WHEN LEFT(model,2) = N'VN' THEN N'카세트' ELSE 구분 END+model as model, sum(dist_amt) as amt
            from doi_smce_cost
            where yyyymm = @yyyymm and site = @site and sub_name like '판)광고선전비%' and sel_code=@SEL_CODE
            group by CASE WHEN LEFT(model,2) = N'VN' THEN N'카세트' ELSE 구분 END+model
            union all
            select 115 as rn, '    (24) 판)무형자산상각비' as gubun, CASE WHEN LEFT(model,2) = N'VN' THEN N'카세트' ELSE 구분 END+model as model, sum(dist_amt) as amt
            from doi_smce_cost
            where yyyymm = @yyyymm and site = @site and sub_name like '판)무형자산상각비%' and sel_code=@SEL_CODE
            group by CASE WHEN LEFT(model,2) = N'VN' THEN N'카세트' ELSE 구분 END+model
            union all
            select 117 as rn, '    (25) 판)견본비' as gubun, CASE WHEN LEFT(model,2) = N'VN' THEN N'카세트' ELSE 구분 END+model as model, sum(dist_amt) as amt
            from doi_smce_cost
            where yyyymm = @yyyymm and site = @site and sub_name like '판)견본비%' and sel_code=@SEL_CODE
            group by CASE WHEN LEFT(model,2) = N'VN' THEN N'카세트' ELSE 구분 END+model
            union all
            select 119 as rn, '    (26) 판)사용권자산감가상각비' as gubun, CASE WHEN LEFT(model,2) = N'VN' THEN N'카세트' ELSE 구분 END+model as model, sum(dist_amt) as amt
            from doi_smce_cost
            where yyyymm = @yyyymm and site = @site and sub_name like '판)사용권자산상각비%' and sel_code=@SEL_CODE
            group by CASE WHEN LEFT(model,2) = N'VN' THEN N'카세트' ELSE 구분 END+model
            union all
            select 122 as rn, '    (27) 판)주식보상비용' as gubun, CASE WHEN LEFT(model,2) = N'VN' THEN N'카세트' ELSE 구분 END+model as model, sum(dist_amt) as amt
            from doi_smce_cost
            where yyyymm = @yyyymm and site = @site and sub_name like '판)주식보상비용%' and sel_code=@SEL_CODE
            group by CASE WHEN LEFT(model,2) = N'VN' THEN N'카세트' ELSE 구분 END+model
            union all
            select 124 as rn, '    (28) 판)해외시장개척비' as gubun, CASE WHEN LEFT(model,2) = N'VN' THEN N'카세트' ELSE 구분 END+model as model, sum(dist_amt) as amt
 from doi_smce_cost
            where yyyymm = @yyyymm and site = @site and sub_name like '판)해외시장개척비%' and sel_code=@SEL_CODE
            group by CASE WHEN LEFT(model,2) = N'VN' THEN N'카세트' ELSE 구분 END+model
            union all
            select 999 as rn, '    (29) 합계' as gubun, CASE WHEN LEFT(model,2) = N'VN' THEN N'카세트' ELSE 구분 END+model as model, sum(dist_amt) as amt
            from doi_smce_cost
            where yyyymm = @yyyymm and site = @site and sel_code=@SEL_CODE
            group by CASE WHEN LEFT(model,2) = N'VN' THEN N'카세트' ELSE 구분 END+model
            ) Y
            on 1=1
            and X.rn = Y.rn 
            and X.gubun = Y.gubun 
            and X.model = Y.model
        )
        SELECT * INTO #sourceTable1 FROM sourceTable;
        
        SELECT @Prod_Rate = sum(case when model like '양산%' then amt else 0 end)/SUM(amt) from #sourceTable1;
        SELECT @Dev_Rate  = sum(case when model like '개발%' then amt else 0 end)/SUM(amt) from #sourceTable1;
        SELECT @Cas_Rate  = sum(case when model like N'카세트%' then amt else 0 end)/SUM(amt) from #sourceTable1;   -- [2026-09-16a]

        SET @SQL = '
SELECT 
   '+ @Null_Columns +'
FROM (
    select * from #sourceTable1
    union all 
    select ''X합계'' model, rn, gubun, CASE WHEN RN=0 THEN '+CAST(@Prod_Rate as varchar)+' ELSE sum(amt) END amt from #sourceTable1 
	where model like ''양산%'' group by rn, gubun
    union all 
    select ''Y합계'' model, rn, gubun, CASE WHEN RN=0 THEN '+CAST(@Dev_Rate as varchar)+' ELSE sum(amt) END amt from #sourceTable1 
	where model like ''개발%'' group by rn, gubun
    union all /* [2026-09-16a] 카세트 합계 */
    select ''W합계'' model, rn, gubun, CASE WHEN RN=0 THEN '+CAST(@Cas_Rate as varchar)+' ELSE sum(amt) END amt from #sourceTable1 
	where model like N''카세트%'' group by rn, gubun
    union all 
    select ''Z합계'' model, rn, gubun, CASE WHEN RN=0 THEN 1 ELSE sum(amt) END amt from #sourceTable1 group by rn, gubun
) AS SourceTable
PIVOT 
(
    SUM(AMT)
    FOR model IN (' + @Columns + ')
) AS PivotTable
order by 1,2 desc;';
        
--select @SQL;
        EXEC sp_executesql @SQL;
        COMMIT TRANSACTION;
       DROP TABLE #sourceTable1;	
    END TRY
    
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        SELECT ERROR_MESSAGE() AS ErrorMessage;
    END CATCH;
END;
