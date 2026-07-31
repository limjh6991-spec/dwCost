CREATE OR ALTER PROCEDURE dbo.UP_VN_ACCT_EXPEN
(
    @YYYYMM varchar(10),
    @SITE   varchar(5),
    @SEL_CODE varchar(6)
)
AS
/* [VN 리팩토링 260731] 가공비 원천 집계 전용 → doi_acct_expen
   UP_VN_EXPEN_MATL 에서 "doi_acct_expen 생성까지"만 분리(부서/계정 투입비용).
   이후 배부(doi_expen_matl)·기초분리(doi_boh_amt)는 신규 파이프라인(UP_VN_EXPN_INPUT/UP_VN_COST_BOH)이 대체.
   포함: 마감체크 + 기본데이터 체크 + ADJ_DOI_PROD_SUBUL(생산수불 조정) + DOI_ACCT_EXPEN 재생성. */
BEGIN
    SET NOCOUNT ON;
    SET LOCK_TIMEOUT 10000;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    DECLARE @Message NVARCHAR(MAX)='', @CNT INT=0, @CHECK BIT=0;

    IF EXISTS (SELECT 1 FROM DOI_CLOSING_MONTH WHERE YYYYMM=@YYYYMM AND IS_CLOSED='Y')
    BEGIN
        RAISERROR(N'마감된 결산월(%s)은 실행할 수 없습니다.', 16, 1, @YYYYMM); RETURN;
    END

    BEGIN TRY
    SET @Message = '[START] '+CONVERT(VARCHAR(19),GETDATE(),120)+CHAR(9)+N'- 부서/원가항목별 투입비용(DOI_ACCT_EXPEN) '+@YYYYMM+N'월 '
                 + CASE WHEN @SITE='HQ' THEN N'본사' ELSE N'VINA' END + N' 집계 시작';

    -- 기본데이터 체크
    SELECT @CNT=COUNT(*) FROM DOI_ACCT WHERE yyyymm=@YYYYMM AND site=@SITE;
    IF @CNT=0 BEGIN SET @Message=@Message+CHAR(10)+'[ERROR] 원가계정정보(DOI_ACCT) 없음'; SET @CHECK=1; END
    SELECT @CNT=COUNT(*) FROM DOI_DEPT WHERE yyyymm=@YYYYMM AND site=@SITE;
    IF @CNT=0 BEGIN SET @Message=@Message+CHAR(10)+'[ERROR] 부서정보(DOI_DEPT) 없음'; SET @CHECK=1; END
    SELECT @CNT=COUNT(*) FROM DOI_DEPT_COST WHERE yyyymm=@YYYYMM AND site=@SITE;
    IF @CNT=0 BEGIN SET @Message=@Message+CHAR(10)+'[ERROR] 부서별·계정별 투입비용(DOI_DEPT_COST) 없음'; SET @CHECK=1; END
    SELECT @CNT=COUNT(*) FROM V_DOI_PROD_SUBUL WHERE yyyymm=@YYYYMM AND site=@SITE;
    IF @CNT=0 BEGIN SET @Message=@Message+CHAR(10)+'[ERROR] 생산수불(DOI_PROD_SUBUL) 없음'; SET @CHECK=1; END
    SELECT @CNT=COUNT(*) FROM DOI_MODEL_MAST WHERE yyyymm=@YYYYMM AND site=@SITE;
    IF @CNT=0 BEGIN SET @Message=@Message+CHAR(10)+'[ERROR] 면적정보(DOI_MODEL_MAST) 없음'; SET @CHECK=1; END
    IF @CHECK=1 BEGIN SELECT @Message as retMessage; RETURN -1; END

    -- 창고 입고수량으로 생산수불 FAB OUT/EOH 조정
    DECLARE @Ret_M nvarchar(MAX)='';
    EXEC ADJ_DOI_PROD_SUBUL @YYYYMM=@YYYYMM, @SITE=@SITE, @R_Message=@Ret_M OUTPUT;
    SET @Message = @Message + @Ret_M;

    -- DOI_ACCT_EXPEN 재생성
    DELETE FROM DOI_ACCT_EXPEN WHERE yyyymm=@YYYYMM AND site=@SITE AND sel_code=@SEL_CODE;
    SET @Message = @Message + CHAR(10)+' [INFO] '+CONVERT(VARCHAR(19),GETDATE(),120)+CHAR(9)+N'- 기존 '+CAST(@@ROWCOUNT AS VARCHAR)+N'건 삭제';

    INSERT INTO DOI_ACCT_EXPEN
       (YYYYMM, SEL_CODE, SITE, ACCT_CLASS, DEPT, ACCT, ACCT_NAME, ITEM_NAME, ACCT_AMT, DBT_AMT, CRT_AMT, EXPEN_SEL, EXPEN_SEL명, DISP_SEQ)
    SELECT a.yyyymm, @SEL_CODE, a.site,
        CASE WHEN 비용구분='판관' THEN 'CC' WHEN 비용구분='제조' THEN 'AA' ELSE 비용구분 END,
        b.dept, a.계정코드, a.계정과목, c.소분류, 차변금액, 차변금액, 대변금액, c.expen_sel, c.expen_sel명, c.disp_seq
    FROM DOI_DEPT_COST a
    LEFT JOIN (SELECT DISTINCT dept, dept_name FROM doi_dept WHERE yyyymm=@YYYYMM AND site=@SITE) b ON (a.코스트센터=b.dept_name)
    LEFT JOIN doi_acct c ON (a.yyyymm=c.yyyymm AND a.sel_code=c.sel_code AND a.site=c.site AND a.계정코드=c.acct)
    WHERE a.yyyymm=@YYYYMM AND a.site=@SITE AND COALESCE(NULLIF(a.제외여부,''),'N')='N';
    SET @Message = @Message + CHAR(10)+' [INFO] '+CONVERT(VARCHAR(19),GETDATE(),120)+CHAR(9)+N'- DOI_ACCT_EXPEN '+CAST(@@ROWCOUNT AS VARCHAR)+N'건 입력';

    SET @Message = @Message + CHAR(10)+'[FINISH] '+CONVERT(VARCHAR(19),GETDATE(),120)+CHAR(9)+N'- 가공비 원천집계(DOI_ACCT_EXPEN) 완료';
    INSERT INTO doi_execlog (yyyymm,sel_code,site,exec_date,rslt_message,exec_user,menu_id,proc_name,exec_rslt)
      VALUES (@YYYYMM,@SEL_CODE,@SITE,getdate(),@Message,'system',N'제조원가집계','UP_VN_ACCT_EXPEN','SUCCESS');
    SELECT @Message as retMessage; RETURN 0;
    END TRY
    BEGIN CATCH
       SET @Message = @Message + CHAR(10)+'[ERROR] '+CONVERT(VARCHAR(19),GETDATE(),120)+CHAR(9)+ERROR_MESSAGE();
       INSERT INTO doi_execlog (yyyymm,sel_code,site,exec_date,rslt_message,exec_user,menu_id,proc_name,exec_rslt)
         VALUES (@YYYYMM,@SEL_CODE,@SITE,getdate(),@Message,'system',N'제조원가집계','UP_VN_ACCT_EXPEN','FAIL');
       SELECT @Message as retMessage; RETURN -1;
    END CATCH
END
