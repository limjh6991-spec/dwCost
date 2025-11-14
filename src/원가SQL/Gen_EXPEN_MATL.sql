CREATE                       Procedure Gen_EXPEN_MATL
(
    @YYYYMM varchar(10),--집계 년/월 설정
    @SITE varchar(5)  --사업장코드 (본사 : HQ, 베트남 : VN)
)
AS
BEGIN
	SET NOCOUNT ON;
    SET LOCK_TIMEOUT 10000; -- 10초로 증가
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED; -- 격리 수준 변경
    DECLARE  @Message  NVARCHAR(MAX)=''
    
    -- 1초 대기
    WAITFOR DELAY '00:00:01';
      	
   	BEGIN TRY
      /*DECLARE @YYYYMM VARCHAR(6) = '202507', --집계 년/월 설정
            @SITE   VARCHAR(2) = 'HQ';*/
   	
	SET  @Message =  '[START]  ' + CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 경비집계(DOI_EXPEN_MATL) 테이블에 '+@YYYYMM + '월 '
						+ CASE WHEN @SITE ='HQ' THEN '본사' ELSE 'VINA' END + '데이타 집계를 시작합니다';
	
	DECLARE @CNT INT = 0,
			@CHECK BIT = 0;
	--데이타 체크
	SELECT @CNT = count(*)
		FROM DOI_ACCT
      WHERE yyyymm=@YYYYMM
        and site  =@SITE;
	IF @CNT = 0 BEGIN
		SET @Message = @Message + char(10) + '[ERROR] ' + CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 원가계정정보(DOI_ACCT) 테이블에 '+@YYYYMM + '월 '
						+ CASE WHEN @SITE ='HQ' THEN '본사' ELSE 'VINA' END + ' 데이타가 없습니다';
		SET @CHECK = 1;
	END
	
	SELECT @CNT = count(*)
		FROM DOI_DEPT
      WHERE yyyymm=@YYYYMM
        and site  =@SITE;
	IF @CNT = 0 BEGIN
		SET @Message = @Message + char(10)+ '[ERROR] ' + CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 부서정보(DOI_DEPT) 테이블에 '+@YYYYMM + '월 '
						+ CASE WHEN @SITE ='HQ' THEN '본사' ELSE 'VINA' END + ' 데이타가 없습니다';
		SET @CHECK = 1;
	END

	SELECT @CNT = count(*)
		FROM DOI_DEPT_COST
      WHERE yyyymm=@YYYYMM
        and site  =@SITE;
	IF @CNT = 0 BEGIN
		SET @Message = @Message + char(10)+ '[ERROR] ' + CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 부서별,계정별 투입비용(DOI_DEPT_COST) 테이블에 '+@YYYYMM + '월 '
						+ CASE WHEN @SITE = 'HQ' THEN '본사' ELSE 'VINA' END + ' 데이타가 없습니다';
		SET @CHECK = 1;
	END
	
	SELECT @CNT = count(*)
		FROM DOI_PROD_SUBUL
      WHERE yyyymm=@YYYYMM
        and dw_site  =@SITE;
	IF @CNT = 0 BEGIN
		SET @Message = @Message + char(10)+'[ERROR] ' + CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 생산수불(DOI_PROD_SUBUL) 테이블에 '+@YYYYMM + '월 '
						+ CASE WHEN @SITE ='HQ' THEN '본사' ELSE 'VINA' END + ' 데이타가 없습니다';
		SET @CHECK = 1;
	END
	
	SELECT @CNT = count(*)
		FROM DOI_MODEL_MAST
      WHERE yyyymm=@YYYYMM
        and site  =@SITE;
	IF @CNT = 0 BEGIN
		SET @Message = @Message + char(10)+'[ERROR] '+  CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 면적정보(DOI_MODEL_MAST) 테이블에 '
				+ @YYYYMM + '월 '+ CASE WHEN @SITE ='HQ' THEN '본사' ELSE 'VINA' END + ' 데이타가 없습니다';
		SET @CHECK = 1;
	END
	
	SELECT @CNT = count(*)
		FROM DOI_CASSETTE_RESC
      WHERE yyyymm=@YYYYMM
        and site  =@SITE;
	IF @CNT = 0 BEGIN
		SET @Message = @Message + char(10)+'[ERROR] '+  CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 카세트 발생비용(DOI_CASSETTE_RESC) 테이블에 '
				+@YYYYMM + '월 '+ CASE WHEN @SITE ='HQ' THEN '본사' ELSE 'VINA' END + ' 데이타가 없습니다';
		SET @CHECK = 1;
	END

	IF @CHECK = 1 BEGIN 
		SET @Message = @Message + char(10)+'[ERROR] '+  CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 기본정보 테이블들에 '
				+@YYYYMM + '월 '+ CASE WHEN @SITE ='HQ' THEN '본사' ELSE 'VINA' END + ' 데이타가 없습니다';
		SELECT @Message as retMessage;
		RETURN -1;
	END

	--삭제
      BEGIN TRANSACTION;
      DELETE FROM DOI_ACCT_EXPEN
      WHERE 1=1
        and yyyymm = @YYYYMM
        and site  = @SITE;
      
      SET  @Message =  @Message + char(10) + ' [INFO] ' + CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 부서별/원가항목별 투입비용(DOI_ACCT_EXPEN) 테이블에 '+@YYYYMM + '월 '
						+ CASE WHEN @SITE ='HQ' THEN '본사' ELSE 'VINA' END + ' 데이타 '+CAST(@@ROWCOUNT AS VARCHAR) +'건을 삭제했습니다';

      INSERT INTO DOI_ACCT_EXPEN
		(YYYYMM, SEL_CODE, SITE, ACCT_CLASS, DEPT, ACCT, SUB_NAME, ITEM_NAME, ACCT_AMT, EXPEN_SEL, EXPEN_SEL명)
		select
			a.yyyymm as YYYYMM,
			a.sel_code as SEL_CODE,
			a.site as SITE,
			case
				when 비용구분 = '판관' then 'CC'
				when 비용구분 = '제조' then 'AA'
			else 비용구분	
			end as ACCT_CLASS,
			b.dept as DEPT,
			--코스트센터,
			--코스트센터분류,
			--코스트센터유형,
			a.계정코드 as ACCT ,
			c.중분류 as SUB_NAME,
			c.소분류 as ITEM_NAME,
			--계정과목,
			--비용구분,
			차변금액 as ACCT_AMT,
			c.expen_sel as EXPEN_SEL,
			c.expen_sel명 as EXPEN_SEL명 --INTO DOI_ACCT_EXPEN
		from
			DOI_DEPT_COST a
		left join DOI_DEPT b on (a.yyyymm= b.yyyymm	and a.sel_code = b.sel_code	and a.site = b.site	and a.코스트센터 = b.dept_name)
		left join doi_acct c on (a.yyyymm= c.yyyymm	and a.sel_code = c.sel_code	and a.site = c.site	and a.계정코드 = c.acct)
		where 1=1
		  and a.yyyymm = @YYYYMM
          and a.site  = @SITE;
      SET  @Message =  @Message + char(10) + ' [INFO] ' + CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 부서별/원가항목별 투입비용(DOI_ACCT_EXPEN) 테이블에 '+@YYYYMM + '월 '
						+ CASE WHEN @SITE ='HQ' THEN '본사' ELSE 'VINA' END + ' 데이타 '+CAST(@@ROWCOUNT AS VARCHAR) +'건을 입력했습니다';
   
      DELETE FROM DOI_EXPEN_MATL
      WHERE 1=1
 and yyyymm = @YYYYMM
        and site  = @SITE;
      
      SET  @Message =  @Message + char(10) + ' [INFO] ' + CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 경비집계(DOI_EXPEN_MATL) 테이블에 '+@YYYYMM + '월 '
						+ CASE WHEN @SITE ='HQ' THEN '본사' ELSE 'VINA' END + ' 데이타 '+CAST(@@ROWCOUNT AS VARCHAR) +'건을 삭제했습니다';
 
      WITH MODEL_SUBUL AS ( --모델별 배부총량 계산 :생산수불(in+out+loss)/2) * Cell면적 
      select
         a.YYYYMM,
         a.dw_SITE as site,
         a.구분,
         a.도우모델 as MODEL,
         b.xy as 면적,
         sum((IN_MONTH + OUT_MONTH + LOSS_MONTH))/ 2 as adj_qty,
         sum((IN_MONTH + OUT_MONTH + LOSS_MONTH)/ 2)*1.0 as  dist_in,
         --sum(IN_MONTH + EOH_MONTH)*1.0 dist_in,
         sum(a.boh_month) as boh_qty,
         sum(a.in_month)  as in_qty,
         sum(a.eoh_month) as eoh_qty,
         sum(a.out_month) as out_qty,
         sum(a.loss_month)as loss_qty,
         0 as bad_qty,  --추후 반영
         0 as Transfer_qty  --추후 반영
         --select *
      FROM
         DOI_PROD_SUBUL A         --모델병,구분(양산/개발)별 생산 수불
      LEFT JOIN DOI_MODEL_MAST B ON     --모델별 면적정보
         (a.도우모델 = b.MODEL and a.yyyymm=b.YYYYMM and a.dw_SITE = b.SITE)
 	  where 1=1 
        and a.yyyymm    = @YYYYMM
        and a.dw_site   = @SITE
      GROUP BY
         a.YYYYMM,
         a.dw_SITE,
         a.도우모델,
         a.구분,b.xy
      ),
      MODEL_RATE as( ----모델병,구분(양산/개발)별 배부 비율 계산
      select
         YYYYMM,
         SITE,
         MODEL,
         구분,
         면적,
         dist_in / sum(dist_in) over () dist_rate,
         adj_qty,
         boh_qty,
         in_qty,
         eoh_qty,
         out_qty,
         loss_qty,
         bad_qty,
         Transfer_qty
      from
         MODEL_SUBUL
      ),
      sum_expen as( --집계년월의 계정별 (비목/세목) 발생비용 집계 
      select
         a.YYYYMM,
         a.SITE,
         b.대분류 SUB_NAME,
         b.소분류 ITEM_NAME,
         b.EXPEN_SEL,
         b.EXPEN_SEL명,
         sum(ACCT_AMT) total 
      from
         doi_acct_expen a
      left join doi_acct b on
         (a.acct = b.acct and a.yyyymm=b.yyyymm)
      where
         a.yyyymm = @YYYYMM
         and a.acct like '5%' --제조경비만
         and a.acct not like '51%' --재료비 제외
         and a.dept != '448' --카세트팀 제외
      group by
         a.YYYYMM,
         a.SITE,
         b.대분류,
         b.소분류,
         b.EXPEN_SEL,
         b.EXPEN_SEL명      
      )--,boh_in_unitcost as ( -- 단가 ,boh금액, in금액 산출
      INSERT INTO DOI_EXPEN_MATL
      (YYYYMM,SEL_CODE,SITE,구분,model,면적,dist_rate,SUB_NAME,ITEM_NAME,EXPEN_SEL,EXPEN_SEL명,adj_qty, boh_qty, in_qty,eoh_qty, out_qty,loss_qty,bad_qty,transfer_qty,unit_cost, boh, [in])
      select
         a.YYYYMM,
         'ACTUAL' as sel_code,
         a.SITE,
         b.구분,
         b.model,
         b.면적,
         b.dist_rate,
         a.SUB_NAME,
         a.ITEM_NAME,
         a.EXPEN_SEL,
         a.EXPEN_SEL명,
         b.adj_qty,
         b.boh_qty,
         b.in_qty,
         b.eoh_qty,
         b.out_qty,
         b.loss_qty,
         b.bad_qty,
         b.transfer_qty,
         coalesce((round(a.total * b.dist_rate / 2,0) + round(a.total * b.dist_rate,0))
               / (nullif((b.eoh_qty / 2),0)+ b.out_qty + b.bad_qty + b.transfer_qty),0) as unit_cost, --(boh금액+in금액)/((eoh수량/2)+out수량+bad수량+Transfer수량)
         round(a.total * b.dist_rate / 2,0) as boh,  --boh금액 (초기에는 in금액의 1/2)
         round(a.total * b.dist_rate,0) as "in"  --in금액
      from
         sum_expen a
      left join MODEL_RATE b on
         dist_rate > 0.0
    	order by 5;
      
      SET  @Message =  @Message + char(10) + ' [INFO] ' + CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 경비집계(DOI_EXPEN_MATL) 테이블에 '+@YYYYMM + '월 '
						+ CASE WHEN @SITE ='HQ' THEN '본사' ELSE 'VINA' END + ' 부서별 데이타 '+CAST(@@ROWCOUNT AS VARCHAR) +'건을 집계했습니다';
      --카세팀 입력
      with Cst_distRate as (
      select
         yyyymm,
       site,
         CST_NO,
         sum(IN_QTY) IN_QTY,
         SUM(in_qty) * 1.0 / SUM(SUM(in_qty)) OVER(PARTITION BY yyyymm,site) AS dist_rate
      from   DOI_CASSETTE_RESC
      where 1=1
   and yyyymm = @YYYYMM
         and site = @SITE
      group by
         yyyymm,
         site,
         CST_NO
      ), SUM_CST_TEAM AS(    
      select 
         A.YYYYMM,
         A.SITE,
         B.대분류,
         B.소분류,
         A.EXPEN_SEL,
         B.EXPEN_SEL명,
         SUM(a.ACCT_AMT) amt
      from
         DOI_ACCT_EXPEN a
         Left join doi_acct b on (a.acct=b.acct and a.yyyymm=b.yyyymm and a.site=b.site)
      where 1=1
        and a.yyyymm=@YYYYMM
        and a.site=@SITE
        and a.dept = '448'
      GROUP BY 
         A.YYYYMM,
         A.SITE,
         B.대분류,
         B.소분류,
         A.EXPEN_SEL,
         B.EXPEN_SEL명
      )
      INSERT INTO DOI_EXPEN_MATL
      (YYYYMM,SEL_CODE,SITE,구분,model,dist_rate,SUB_NAME,ITEM_NAME,EXPEN_SEL,EXPEN_SEL명,in_qty,out_qty,[in])
      SELECT
         A.YYYYMM,
         'ACTUAL' as sel_code,
         A.SITE,
         '양산' 구분,
         B.CST_NO model,
         B.Dist_rate,
		 A.대분류 as SUB_NAME,
         A.소분류 as ITEM_NAME,
         A.EXPEN_SEL,
         A.EXPEN_SEL명,
         B.IN_QTY AS IN_QTY,
         B.IN_QTY AS OUT_QTY,
         A.AMT * B.DIST_RATE [IN]
      FROM
         SUM_CST_TEAM A
      LEFT JOIN Cst_distRate B ON (A.YYYYMM=B.YYYYMM AND A.SITE=B.SITE)
      order by B.CST_NO;
      SET  @Message =  @Message + char(10) + ' [INFO] ' + CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 경비집계(DOI_EXPEN_MATL) 테이블에 '+@YYYYMM + '월 '
						+ CASE WHEN @SITE ='HQ' THEN '본사' ELSE 'VINA' END + '카세스팀 데이타 '+CAST(@@ROWCOUNT AS VARCHAR) +'건을 집계했습니다';
      
      -- ========================================
      -- 데이터 무결성 검증
      -- ========================================
      DECLARE @SOURCE_AMT DECIMAL(18,2) = 0,
              @TARGET_AMT DECIMAL(18,2) = 0,
              @DIFF_AMT DECIMAL(18,2) = 0,
              @MISSING_DEPT VARCHAR(MAX) = '',
              @MISSING_ACCT VARCHAR(MAX) = '';
      
      -- 1. 소스 데이터 금액 합계 (DOI_ACCT_EXPEN)
      SELECT @SOURCE_AMT = ISNULL(SUM(ACCT_AMT), 0)
      FROM DOI_ACCT_EXPEN
      WHERE yyyymm = @YYYYMM AND site = @SITE;
      
      -- 2. 타겟 데이터 금액 합계 (DOI_EXPEN_MATL)
      SELECT @TARGET_AMT = ISNULL(SUM([IN]), 0)
      FROM DOI_EXPEN_MATL
      WHERE YYYYMM = @YYYYMM AND SITE = @SITE;
      
      SET @DIFF_AMT = @SOURCE_AMT - @TARGET_AMT;
      
      SET  @Message =  @Message + char(10) + '[CHECK] ' + CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)
                    + '- 소스금액: ' + FORMAT(@SOURCE_AMT, 'N0') + '원, '
                    + '타겟금액: ' + FORMAT(@TARGET_AMT, 'N0') + '원, '
                    + '차이: ' + FORMAT(@DIFF_AMT, 'N0') + '원';
      
      -- 3. 금액 차이가 1원 이상이면 누락 데이터 확인
      IF ABS(@DIFF_AMT) > 1 BEGIN
          -- 누락된 부서 확인
          SELECT @MISSING_DEPT = STUFF((
              SELECT DISTINCT ', ' + a.DEPT + '(' + b.DEPT_NAME + ')'
              FROM DOI_ACCT_EXPEN a
              LEFT JOIN DOI_DEPT b ON (a.yyyymm = b.yyyymm AND a.site = b.site AND a.dept = b.dept)
              LEFT JOIN DOI_EXPEN_MATL c ON (a.yyyymm = c.YYYYMM AND a.site = c.SITE AND a.dept = c.dept)
              WHERE a.yyyymm = @YYYYMM AND a.site = @SITE
                AND c.dept IS NULL
              FOR XML PATH('')
          ), 1, 2, '');
          
          -- 누락된 계정 확인
          SELECT @MISSING_ACCT = STUFF((
              SELECT DISTINCT ', ' + a.ACCT + '(' + b.ACCT_NAME + ')'
              FROM DOI_ACCT_EXPEN a
              LEFT JOIN DOI_ACCT b ON (a.yyyymm = b.yyyymm AND a.site = b.site AND a.acct = b.acct)
              LEFT JOIN DOI_EXPEN_MATL c ON (a.yyyymm = c.YYYYMM AND a.site = c.SITE AND a.acct = c.acct)
              WHERE a.yyyymm = @YYYYMM AND a.site = @SITE
                AND c.acct IS NULL
              FOR XML PATH('')
          ), 1, 2, '');
          
          IF @MISSING_DEPT IS NOT NULL AND LEN(@MISSING_DEPT) > 0 BEGIN
              SET  @Message =  @Message + char(10) + '[WARN] ' + CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)
                            + '- 누락 부서: ' + @MISSING_DEPT;
          END
          
          IF @MISSING_ACCT IS NOT NULL AND LEN(@MISSING_ACCT) > 0 BEGIN
              SET  @Message =  @Message + char(10) + '[WARN] ' + CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)
                            + '- 누락 계정: ' + @MISSING_ACCT;
          END
          
          -- 조인 실패 원인 확인
          DECLARE @MISSING_DEPT_IN_MASTER INT = 0;
          SELECT @MISSING_DEPT_IN_MASTER = COUNT(DISTINCT a.dept)
          FROM DOI_ACCT_EXPEN a
          LEFT JOIN DOI_DEPT b ON (a.yyyymm = b.yyyymm AND a.site = b.site AND a.dept = b.dept)
          WHERE a.yyyymm = @YYYYMM AND a.site = @SITE
            AND b.dept IS NULL;
          
          IF @MISSING_DEPT_IN_MASTER > 0 BEGIN
              SET  @Message =  @Message + char(10) + '[WARN] ' + CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)
                            + '- DOI_DEPT 마스터에 없는 부서: ' + CAST(@MISSING_DEPT_IN_MASTER AS VARCHAR) + '개';
          END
          
          SET  @Message =  @Message + char(10) + '[WARN] ' + CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)
                        + '- 경비집계 데이터 불일치 발생! 원인을 확인하세요.';
      END
      ELSE BEGIN
          SET  @Message =  @Message + char(10) + '[CHECK] ' + CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)
                        + '- 경비집계 데이터 무결성 검증 완료 (일치)';
      END
      
      SET  @Message =  @Message + char(10) + '[FINISH] ' + CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 경비집계(DOI_EXPEN_MATL) 테이블에 '+@YYYYMM + '월 '
						+ CASE WHEN @SITE ='HQ' THEN '본사' ELSE 'VINA' END + ' 데이타 집계 완료했습니다';
      COMMIT TRANSACTION;
      SELECT @Message as retMessage;
      RETURN 0;
      END TRY
   
   BEGIN CATCH
   ROLLBACK TRANSACTION;
       SET  @Message =  @Message + char(10) + '[ERROR] '+  CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+(SELECT ERROR_MESSAGE());-- AS ErrorMessage;
   	SELECT @Message as retMessage;
   END CATCH;
END;