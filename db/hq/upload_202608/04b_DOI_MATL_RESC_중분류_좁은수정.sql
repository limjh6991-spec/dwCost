/* ============================================================
   DOI_MATL_RESC / DOI_HQ_STOCK_DETAIL  202608  중분류 복구
   ── 전체 재적재(04_DOI_MATL_RESC.sql) 대체용 "좁은 수정"
   DB : 도우제조원가시스템 (10.100.40.17,14233)

   [원인]
     UP_HQ_IF_XFORM_STOCK_DETAIL 이 스테이징 컬럼 s.UMItmeClassMName(오타)을 읽는데,
     영림원 ERP 응답 키는 UMItemClassMName 이라 스테이징 컬럼 자체가 278행 전량 NULL.
     원값은 DOI_HQ_IF_STOCK_DETAIL.RAW_JSON 에 온전히 남아 있다(278/278).

   [검증 완료]
     - JSON_VALUE(RAW_JSON,'$.UMItemClassMName') : 278행, NULL 0, 공백 0, 최대길이 8
     - 08월 재고수불부(260910).xlsx '재고금액(202608)' 중분류와 278/278 완전 일치 (불일치 0)
     - 중분류 외 텍스트 11개 컬럼(자산처리계정·품목자산분류·재고자산종류·매출원가계정·
       대분류·소분류·품목기타분류·품명·품번·규격·단위)은 엑셀과 이미 278/278 일치
     - 조인키 품번=ItemNo : 양쪽 모두 278행 유일, 매칭 278 / 미매칭 0
     - 202608 결산 산출물 전무(doi_mat_amt/doi_mat_cost/DOI_EXPEN_MATL/DOI_COST/
       DOI_STCO/DOI_SCOF/DOI_POST/doi_smce_cost 모두 0행) → 무효화할 하위데이터 없음

   [선행조건] 실행 전 스테이징이 202608 스냅샷인지 확인 (아래 0단계가 자동 검사)
   ============================================================ */
SET NOCOUNT ON;
SET XACT_ABORT ON;

-- 0) 가드: 스테이징이 202608 스냅샷인지 확인 (스테이징엔 YYYYMM 컬럼이 없다)
DECLARE @cnt INT, @preAmt NUMERIC(20,2), @inputAmt NUMERIC(20,2);
SELECT @cnt=COUNT(*), @preAmt=SUM(CAST(PreAmt AS NUMERIC(20,2))), @inputAmt=SUM(CAST(InputAmt AS NUMERIC(20,2)))
  FROM DOI_HQ_IF_STOCK_DETAIL WHERE SITE='HQ' AND SEL_CODE='ACTUAL';
IF @cnt <> 278 OR @preAmt <> 2665212610.00 OR @inputAmt <> 670021519.00
BEGIN
    RAISERROR('스테이징 스냅샷이 202608이 아님 (cnt=%d). API를 다시 호출했다면 이 스크립트 대신 04_DOI_MATL_RESC.sql(전체 재적재)을 쓸 것.',16,1,@cnt);
    RETURN;
END

BEGIN TRAN;

-- 1) 재료비원장 (결산 입력) : 278행
UPDATE m
   SET m.중분류 = LTRIM(RTRIM(JSON_VALUE(s.RAW_JSON,'$.UMItemClassMName')))
  FROM DOI_MATL_RESC m
  JOIN DOI_HQ_IF_STOCK_DETAIL s
    ON s.ItemNo = m.품번 AND s.SITE = m.SITE AND s.SEL_CODE = m.SEL_CODE
 WHERE m.YYYYMM = '202608' AND m.SITE = 'HQ' AND m.SEL_CODE = 'ACTUAL'
   AND NULLIF(LTRIM(RTRIM(JSON_VALUE(s.RAW_JSON,'$.UMItemClassMName'))),'') IS NOT NULL;
DECLARE @r1 INT = @@ROWCOUNT;

-- 2) 재고금액상세 그리드 C0007014 (동일 결함, 화면 표시용) : 278행
UPDATE d
   SET d.중분류 = LTRIM(RTRIM(JSON_VALUE(s.RAW_JSON,'$.UMItemClassMName')))
  FROM DOI_HQ_STOCK_DETAIL d
  JOIN DOI_HQ_IF_STOCK_DETAIL s ON s.ItemNo = d.품번
 WHERE d.yyyymm = '202608'
   AND NULLIF(LTRIM(RTRIM(JSON_VALUE(s.RAW_JSON,'$.UMItemClassMName'))),'') IS NOT NULL;
DECLARE @r2 INT = @@ROWCOUNT;

-- 3) 검증 : 중분류 NULL 0건 + 원가자재분류 파생 분포
DECLARE @nul INT = (SELECT COUNT(*) FROM DOI_MATL_RESC WHERE YYYYMM='202608' AND SITE='HQ' AND 중분류 IS NULL);
IF @r1 <> 278 OR @r2 <> 278 OR @nul <> 0
BEGIN
    ROLLBACK TRAN;
    RAISERROR('검증 실패: MATL_RESC=%d, STOCK_DETAIL=%d, 잔여NULL=%d (기대 278/278/0)',16,1,@r1,@r2,@nul);
    RETURN;
END

COMMIT TRAN;
PRINT '완료: DOI_MATL_RESC ' + CAST(@r1 AS VARCHAR) + '행, DOI_HQ_STOCK_DETAIL ' + CAST(@r2 AS VARCHAR) + '행 갱신';

-- 4) 사후 확인 : 기대 분포 = 필름81 / 우인테크26 / 카세트18 / 트레이13 / SDC12 / 약액11 / 제조기술5 …
SELECT 중분류, COUNT(*) 건수 FROM DOI_MATL_RESC WHERE YYYYMM='202608' AND SITE='HQ'
GROUP BY 중분류 ORDER BY 건수 DESC;

-- 5) UP_DOI_MAT_AMT 가 파생할 원가자재분류 미리보기
--    기대: 필름 306,922,578 / 약액 219,085,346 / 트레이 109,503,347 / 기타 34,510,248 / 원장 0
SELECT CASE WHEN 품명 LIKE '%Tray%' THEN '트레이'
            WHEN 중분류='약액' THEN '약액'
            WHEN 중분류='필름' THEN '필름'
            WHEN 중분류 IN ('SDC','제조기술','공정개발') THEN '원장'
            ELSE '기타' END AS 원가자재분류,
       COUNT(*) 건수, SUM(투입금액) 투입금액
  FROM DOI_MATL_RESC WHERE YYYYMM='202608' AND SITE='HQ'
 GROUP BY CASE WHEN 품명 LIKE '%Tray%' THEN '트레이'
               WHEN 중분류='약액' THEN '약액'
               WHEN 중분류='필름' THEN '필름'
               WHEN 중분류 IN ('SDC','제조기술','공정개발') THEN '원장'
               ELSE '기타' END
 ORDER BY 3 DESC;

/* [영구 수정 — 별도 배포 권장]
   UP_HQ_IF_XFORM_STOCK_DETAIL 본문 2곳의  s.UMItmeClassMName  →  s.UMItemClassMName
   또는 스테이징 적재 매핑(IfService/IfEndpoint)의 컬럼명을 정정할 것.
   고치지 않으면 202609 API 적재에서 동일 증상이 재발한다.                       */
