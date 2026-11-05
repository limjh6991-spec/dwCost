/* ============================================================
   UP_VN_IF_XFORM_ITEM fix261105b — 결산월 이후 ERP에 등록된 품목이 면적기준 정보에 들어가는 문제
   요청: 장시문 프로 10/30 「DWV 2026년도 9월 CMS API 검증 오류내역 송부의 件」, 오기환 차장 11/5 재요청
   현상: 202609 면적기준 정보 353건(8월 301건). 늘어난 52건은 모두 ERP 등록일 2026-10-12~10-27.
         ERP 품목조회(FrmWDAItemList, 등록일 ~2026-09-30)보다 CMS가 많음.
   원인: 품목 API는 호출 시점의 품목 전체를 주는데, 변환에 등록일 조건이 없어 10/30 실행 때 10월 등록 품목까지 9월에 INSERT.
   수정: RegDate의 연월이 @yyyymm 이하인 품목만 반영. 기존 행·수동 보정값 보존 규칙은 그대로.
   데이터: 202609의 10월 이후 등록 52건 삭제(9월 수불에 없는 품목이라 원가 영향 없음) — db/vn/fix_model_mast_202609_regdate.sql
   원복: db/vn_procs/bak261105b/UP_VN_IF_XFORM_ITEM.sql
   ============================================================ */
CREATE OR ALTER PROCEDURE dbo.UP_VN_IF_XFORM_ITEM
  @yyyymm  NVARCHAR(6),
  @selCode NVARCHAR(10) = N'ACTUAL',
  @site    NVARCHAR(4)  = N'VN'
AS
/* 품목(ITEM) 스테이징 → 면적기준정보 DOI_MODEL_MAST[VN]
 *  X=장변(ITEM_CMF_11), Y=단변(ITEM_CMF_12), XY=X×Y, MODEL=품번(ItemNo=도우코드), SPEC='X*Y'
 *  장변/단변은 DataBlock4 부가정보 {RowIDX(0-based), ColIDX 0/1, AddInfoName}를 피벗, 마스터 IDX_NO=RowIDX+1로 조인.
 *  규칙(기존 면적보정과 동일): 기존 행 보존 — 누락 모델은 INSERT, XY가 0/NULL인 행만 채움(수동 보정값 덮지 않음).
 *  INCH/GLASS_THICK/SHEET/BLOCK/CELL/RUN_SIZE 는 API 원천 없음 → NULL(기존값 유지). */
BEGIN
  SET NOCOUNT ON;
  IF OBJECT_ID('tempdb..#src') IS NOT NULL DROP TABLE #src;

  ;WITH cmf AS (
    SELECT c.RowIDX,
           MAX(CASE WHEN c.ColIDX=0 THEN TRY_CONVERT(real, c.AddInfoName) END) AS X,
           MAX(CASE WHEN c.ColIDX=1 THEN TRY_CONVERT(real, c.AddInfoName) END) AS Y
    FROM DOI_VN_IF_ITEM_CMF c
    WHERE c.SITE=@site
    GROUP BY c.RowIDX)
  SELECT i.ItemNo AS MODEL, cmf.X, cmf.Y
  INTO #src
  FROM DOI_VN_IF_ITEM i
  JOIN cmf ON cmf.RowIDX + 1 = i.IDX_NO
  WHERE i.SITE=@site AND ISNULL(i.ItemNo,'')<>''
    AND LEFT(ISNULL(i.RegDate,''),6) <= @yyyymm   /* [2026-11-05b] 결산월 말일까지 ERP에 등록된 품목만 (이후 등록 품목이 이전 달에 들어가던 문제) */
    AND cmf.X IS NOT NULL AND cmf.Y IS NOT NULL AND cmf.X>0 AND cmf.Y>0;

  /* (1) 기존 행 중 XY 미설정(0/NULL)만 채움 — 수동 보정값 보존 */
  UPDATE m
     SET m.X=s.X, m.Y=s.Y, m.XY=CAST(s.X AS real)*CAST(s.Y AS real),
         m.SPEC=CONCAT(CAST(s.X AS varchar(20)),'*',CAST(s.Y AS varchar(20)))
  FROM DOI_MODEL_MAST m JOIN #src s ON s.MODEL=m.MODEL
  WHERE m.YYYYMM=@yyyymm AND m.SITE=@site AND m.SEL_CODE=@selCode AND ISNULL(m.XY,0)=0;
  DECLARE @upd INT = @@ROWCOUNT;

  /* (2) 누락 모델 INSERT — 기존 행 보존(NOT EXISTS) */
  INSERT INTO DOI_MODEL_MAST (YYYYMM,SEL_CODE,SITE,MODEL,SPEC,INCH,GLASS_THICK,SHEET,BLOCK,CELL,RUN_SIZE,X,Y,XY)
  SELECT @yyyymm,@selCode,@site, s.MODEL,
         CONCAT(CAST(s.X AS varchar(20)),'*',CAST(s.Y AS varchar(20))),
         NULL,NULL,NULL,NULL,NULL,NULL, s.X, s.Y, CAST(s.X AS real)*CAST(s.Y AS real)
  FROM #src s
  WHERE NOT EXISTS (SELECT 1 FROM DOI_MODEL_MAST m
                    WHERE m.YYYYMM=@yyyymm AND m.SITE=@site AND m.SEL_CODE=@selCode AND m.MODEL=s.MODEL);
  SELECT @upd + @@ROWCOUNT AS applied;
END;

GO
