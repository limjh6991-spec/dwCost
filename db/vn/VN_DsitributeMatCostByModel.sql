CREATE OR ALTER Procedure VN_DsitributeMatCostByModel
(
	@YYYYMM varchar(10),
	@SITE varchar(4),
	@SEL_CODE varchar(10)
)
AS
BEGIN
	BEGIN TRY
		DECLARE @cols nvarchar(max), @sql nvarchar(max);
		-- 모델별 [수량, 금액] 컬럼 동적 생성 (수량=투입수량*배부율, 금액=배부금액)
		SELECT @cols = STRING_AGG(CAST(
			', SUM(CASE WHEN 도우모델=N''' + 도우모델 + ''' THEN q   END) AS [' + 도우모델 + '_Q]' +
			', SUM(CASE WHEN 도우모델=N''' + 도우모델 + ''' THEN amt END) AS [' + 도우모델 + ']'
			AS nvarchar(max)), '') WITHIN GROUP (ORDER BY 도우모델)
		FROM (SELECT DISTINCT 도우모델 FROM DOI_MAT_COST WITH(NOLOCK)
		      WHERE yyyymm=@YYYYMM AND site=@SITE AND sel_code=@SEL_CODE) m;

		SET @sql = N'
		;WITH mat_info AS (
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
				a.도우모델,
				ROUND(coalesce(q.투입수량,0) * a.배부금액 / NULLIF(SUM(a.배부금액) OVER (PARTITION BY a.자재번호),0), 2) AS q_raw,
				a.배부금액 AS amt
			FROM DOI_MAT_COST a WITH(NOLOCK)
			LEFT JOIN mat_info b ON (a.자재번호 = b.자재번호)
			LEFT JOIN QTY q ON (q.품번 = a.자재번호)
			WHERE a.yyyymm=@ym AND a.site=@st AND a.sel_code=@sc
		),
		ADJ AS (
			SELECT 자재분류,자재대분류,자재중분류,자재명,자재번호,거래처,규격,투입수량,도우모델,amt,
				q_raw + CASE WHEN ROW_NUMBER() OVER (PARTITION BY 자재번호 ORDER BY q_raw DESC, 도우모델)=1 THEN ROUND(투입수량,2) - SUM(q_raw) OVER (PARTITION BY 자재번호) ELSE 0 END AS q
			FROM BASE
		)
		SELECT
			자재분류, 자재대분류, 자재중분류, 자재명, 자재번호, 거래처, 규격 AS size,
			MAX(ROUND(투입수량,2)) AS 전체수량,
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
