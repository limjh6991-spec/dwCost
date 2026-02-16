CREATE   Procedure Gen_Doi_MODEL_MAST
(
    @YYYYMM varchar(10),--집계 년/월 설정
    @SITE varchar(4)  --사업장코드 (본사 : HQ, 베트남 : VN)
)
AS
BEGIN
	  BEGIN TRY
      BEGIN TRANSACTION;
      /*DECLARE @YYYYMM VARCHAR(6) = '202507', --집계 년/월 설정
            @SITE   VARCHAR(2) = 'HQ';*/
      --삭제
      DELETE FROM Doi_MODEL_MAST
      WHERE yyyymm=@YYYYMM
        and site  =@SITE;

		With Spec_split1 as (
		select yyyymm, Model,upper(Spec) spec,Inch,Glass_thick,Sheet,Block,Cell,RUN_SIZE,
			 substring(Spec,1,PATINDEX('%[*|×|X|x]%',Spec)-1) x,
			 substring(Spec,PATINDEX('%[*|×|X|x]%',Spec)+1,len(Spec)) y --select *
		from DOI_면적정보_SRC
		where PATINDEX('%[*|×|X|x]%',Spec)> 0
		and yyyymm=@YYYYMM
		), Spec_split2 as (
		select yyyymm, model,
			   spec,Inch,Glass_thick,Sheet,Block,Cell,RUN_SIZE,
			   replace(case when PATINDEX('%[±|M]%',x)=0 then x else substring(x,1,PATINDEX('%[±|M]%',x)-1) end,',','.') x,
			   replace(case when PATINDEX('%[±|M]%',y)=0 then y else substring(y,1,PATINDEX('%[±|M]%',y)-1) end,',','.') y,
			 row_number() over (partition by model order by x desc, y desc) as rn
		from Spec_split1
		), Spec_split3 as (
		select yyyymm,'ACTUAL' AS sel_code,@SITE AS site,model,
				  spec,Inch,Glass_thick,Sheet,Block,Cell,RUN_SIZE,
			        TRY_CONVERT(real, x) as x,
			        TRY_CONVERT(real, replace(
			            case when PATINDEX('%*%',y)=0 then y else substring(y,1,PATINDEX('%*%',y)-1) end, ',', '.'
			        )) as y
		from Spec_split2
		where rn=1
		)
		insert into doi_model_mast
        (
            YYYYMM, SEL_CODE, SITE, MODEL, SPEC,
            INCH, GLASS_THICK, SHEET, BLOCK, CELL, RUN_SIZE,
            X, Y, XY, ADD_YN
        )
        SELECT
            yyyymm,
            sel_code,
            site,
            model,
            SPEC,
            INCH, GLASS_THICK, SHEET, BLOCK, CELL, RUN_SIZE,
            X, Y,
            CAST(X * Y AS numeric(17,1)) AS XY,
            'N' AS ADD_YN
		from Spec_split3
		order by model
/* SET  @Message =  @Message + char(10) + ' [INFO] ' + CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 경비집계(DOI_EXPEN_MATL) 테이블에 '+@YYYYMM + '월 '
						+ CASE WHEN @SITE ='HQ' THEN '본사' ELSE 'VINA' END + '카세스팀 데이타 '+CAST(@@ROWCOUNT AS VARCHAR) +'건을 입력했습니다';
      SET  @Message =  @Message + char(10) + ' [INFO] ' + CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+'- 경비집계(DOI_EXPEN_MATL) 테이블에 '+@YYYYMM + '월 '
						+ CASE WHEN @SITE ='HQ' THEN '본사' ELSE 'VINA' END + '데이타 입력 완료했습니다';*/
      COMMIT TRANSACTION;
/*      SELECT @Message as retMessage;*/
      RETURN 0;
      END TRY
   
   BEGIN CATCH
       IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
       /*SET  @Message =  @Message + char(10) + '[ERROR] '+  CONVERT(VARCHAR(19), GETDATE(), 120) + char(9)+(SELECT ERROR_MESSAGE());-- AS ErrorMessage;
   	SELECT @Message as retMessage;*/
      THROW;
   END CATCH
END;
