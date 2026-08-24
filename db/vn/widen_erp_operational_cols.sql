/* ============================================================================
 * ERP 인터페이스 xform 대상(운영) 테이블 텍스트 컬럼 확장 (2026-08-24)
 *   증상: ETC_INOUT 실호출 시 "문자열 또는 이진 데이터는 잘립니다.
 *         잘린 값: 'Xuất kho vật liệu kh'" → 운영 doi_vn_etc_inout.원천구분
 *         이 NVARCHAR(20)인데 ERP 베트남어 값(UMEtcOutKindSource 22자) 초과.
 *   원인: staging(DOI_VN_IF_*)은 NVARCHAR(100~200)인데 운영 테이블 텍스트
 *         컬럼이 더 좁아 xform INSERT 시 잘림.
 *   조치: xform 대상 운영 테이블의 좁은 nvarchar(<200) 텍스트 컬럼을
 *         NVARCHAR(200)로 확장(내부/키/월 컬럼 제외). 용량 확장뿐이라
 *         기존 데이터·인덱스·결산 로직에 영향 없음. 멱등(이미 넓으면 스킵).
 *   대상 xform: ETC_INOUT→doi_vn_etc_inout, STOCK_DETAIL→DOI_MATL_RESC/
 *              DOI_VN_STOCK_DETAIL, ITEM_INPUT→DOI_VN_MAT_INPUT
 * ========================================================================== */
SET NOCOUNT ON;

DECLARE @tables TABLE (tbl SYSNAME);
INSERT INTO @tables(tbl) VALUES
    ('doi_vn_etc_inout'), ('DOI_VN_STOCK_DETAIL'), ('DOI_VN_MAT_INPUT'), ('DOI_MATL_RESC');

DECLARE @sql NVARCHAR(MAX) = N'';

SELECT @sql = @sql +
    N'ALTER TABLE ' + QUOTENAME(t.tbl) + N' ALTER COLUMN ' + QUOTENAME(c.name) +
    N' NVARCHAR(200) ' + CASE WHEN c.is_nullable = 1 THEN N'NULL' ELSE N'NOT NULL' END + N';' + CHAR(10)
FROM @tables t
JOIN sys.columns c ON c.object_id = OBJECT_ID(t.tbl)
JOIN sys.types  ty ON c.user_type_id = ty.user_type_id
WHERE ty.name = 'nvarchar'
  AND c.max_length <> -1            -- MAX 제외
  AND c.max_length / 2 < 200        -- 200자 미만만
  AND LOWER(c.name) NOT IN ('yyyymm','edit_user','sel_code','site','request_id','load_dttm')
  -- DOI_MATL_RESC(공유 결산테이블)는 STOCK_DETAIL xform 이 실제 INSERT 하는 텍스트 컬럼만
  AND ( t.tbl <> 'DOI_MATL_RESC'
        OR c.name IN (N'자산처리계정',N'품목자산분류',N'재고자산종류',N'매출원가계정',
                      N'대분류',N'중분류',N'소분류',N'품목기타분류',N'품명',N'품번',N'규격',N'단위') );

PRINT @sql;
EXEC sp_executesql @sql;
PRINT '완료: ERP 운영 테이블 텍스트 컬럼 NVARCHAR(200) 확장';
