CREATE OR ALTER Procedure VN_DsitributeMatCostByModel
(
	@YYYYMM varchar(10),
	@SITE varchar(4),
	@SEL_CODE varchar(10)
)
AS
BEGIN
	-- [VN 260801] 구 DOI_MAT_COST → doi_expn_matl(원가구분='재료비')로 소스 교체
	--   매핑: 항목=자재번호, 투입금액=배부금액, EXPEN_SEL MDAX=원자재/MIAX=부자재. 투입수량은 doi_matl_resc 유지.
	BEGIN TRY
		DECLARE @cols nvarchar(max), @sql nvarchar(max);
		-- [VN 260801] 헤더 품번을 도우모델 → 도우코드 기준으로 변경 (비나 현업 요청). doi_expn_matl.도우코드 사용.
		-- 도우코드별 [수량, 금액] 컬럼 동적 생성
		SELECT @cols = STRING_AGG(CAST(
			', SUM(CASE WHEN 도우코드=N''' + 도우코드 + ''' THEN q   END) AS [' + 도우코드 + '_Q]' +
			', SUM(CASE WHEN 도우코드=N''' + 도우코드 + ''' THEN amt END) AS [' + 도우코드 + ']'
			AS nvarchar(max)), '') WITHIN GROUP (ORDER BY 도우코드)
		FROM (SELECT DISTINCT 도우코드 FROM doi_expn_matl WITH(NOLOCK)
		      WHERE yyyymm=@YYYYMM AND site=@SITE AND sel_code=@SEL_CODE AND 원가구분=N'재료비') m;

		SET @sql = N'
		;WITH MC AS (
			SELECT 도우코드, 항목 AS 자재번호,
			       CASE WHEN EXPEN_SEL=''MDAX'' THEN N''원자재'' ELSE N''부자재'' END AS mat_class,
			       SUM(투입금액) AS 배부금액
			FROM doi_expn_matl WITH(NOLOCK)
			WHERE yyyymm=@ym AND site=@st AND sel_code=@sc AND 원가구분=N''재료비''
			GROUP BY 도우코드, 항목, CASE WHEN EXPEN_SEL=''MDAX'' THEN N''원자재'' ELSE N''부자재'' END
		),
		mat_info AS (
			SELECT coalesce(bom.자재번호, mat.품번) 자재번호,
			       coalesce(bom.자재명, mat.품명) 자재명, mat.규격,
			       coalesce(bom.자재대분류, mat.대분류) 자재대분류,
			       coalesce(bom.자재중분류, mat.중분류) 자재중분류
			FROM ( SELECT DISTINCT 품번,품명,규격,대분류,중분류 FROM doi_matl_resc WITH(NOLOCK) WHERE yyyymm=@ym AND site=@st ) mat
			LEFT JOIN ( SELECT DISTINCT 자재번호,자재명,자재대분류,자재중분류 FROM doi_bom_mast WITH(NOLOCK) WHERE yyyymm=@ym AND site=@st ) bom
			       ON (mat.품번 = bom.자재번호)
		),
		QTY AS ( SELECT 품번, SUM(투입수량) 투입수량 FROM doi_matl_resc WITH(NOLOCK) WHERE yyyymm=@ym AND site=@st GROUP BY 품번 ),
		BASE AS (
			SELECT
				IIF(a.mat_class=N''원자재'', N''원자재'', N''부자재'') AS 자재분류,
				coalesce(b.자재대분류, a.mat_class) AS 자재대분류,
				b.자재중분류,
				coalesce(b.자재명, a.자재번호) AS 자재명,
				a.자재번호,
				CAST(N'''' AS nvarchar(50)) AS 거래처,
				b.규격,
				coalesce(q.투입수량,0) AS 투입수량,
				a.도우코드,
				ROUND(coalesce(q.투입수량,0) * a.배부금액 / NULLIF(SUM(a.배부금액) OVER (PARTITION BY a.자재번호),0), 5) AS q_raw,
				a.배부금액 AS amt
			FROM MC a
			LEFT JOIN mat_info b ON (a.자재번호 = b.자재번호)
			LEFT JOIN QTY q ON (q.품번 = a.자재번호)
		),
		ADJ AS (
			SELECT 자재분류,자재대분류,자재중분류,자재명,자재번호,거래처,규격,투입수량,도우코드,amt,
				q_raw + CASE WHEN ROW_NUMBER() OVER (PARTITION BY 자재번호 ORDER BY q_raw DESC, 도우코드)=1 THEN ROUND(투입수량,5) - SUM(q_raw) OVER (PARTITION BY 자재번호) ELSE 0 END AS q
			FROM BASE
		)
		SELECT
			자재분류, 자재대분류, 자재중분류, 자재명, 자재번호, 거래처, 규격 AS size,
			MAX(ROUND(투입수량,5)) AS 전체수량,
			SUM(amt)      AS [z합계]'
			+ @cols + N'
		FROM ADJ
		GROUP BY 자재분류, 자재대분류, 자재중분류, 자재명, 자재번호, 거래처, 규격
		ORDER BY 자재분류 DESC, 자재번호;';

		EXEC sp_executesql @sql, N'@ym varchar(10),@st varchar(4),@sc varchar(10)', @YYYYMM, @SITE, @SEL_CODE;
	END TRY
	BEGIN CATCH
		SELECT ERROR_MESSAGE() AS ErrorMessage;
	END CATCH;
END;
