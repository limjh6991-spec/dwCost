/* ============================================================
   DOI_IVDD 202608 적재  (재고금액상세 — UP_DOI_SCOF 선행조건)
   DB : 도우제조원가시스템 (10.100.40.17,14233)

   UP_DOI_SCOF 는 DOI_IVDD 를 **읽기만** 한다(INSERT 하는 개체가 DB에 없음).
   202608 이 0행이면 데이터체크에서 RETURN -1 로 종료해 DOI_SCOF 와 기표파일이
   생성되지 않는다.  ※ 어제 '결산이 생성한다'고 한 기재는 오류였다.

   DOI_IVDD 와 DOI_MATL_RESC 는 같은 '재고금액상세' 원천이고 컬럼명만 다르다
   (재고수량A/결산재고수량B/차이수량A_B/재고금액C/결산재고금액D/차이금액C_D).
   202607 실적재분으로 6개 대응컬럼 전수 대조 결과 불일치 0행임을 확인했다.
   따라서 이미 검증이 끝난 DOI_MATL_RESC 202608(278행)에서 그대로 복사한다.

   실행: 검증 통과 시 자동 COMMIT, 실패 시 자동 ROLLBACK
   ============================================================ */
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRAN;

DECLARE @before INT = (SELECT COUNT(*) FROM DOI_IVDD WHERE YYYYMM='202608' AND SITE='HQ');
DELETE FROM DOI_IVDD WHERE YYYYMM='202608' AND SITE='HQ';

INSERT INTO DOI_IVDD ([YYYYMM],[SEL_CODE],[SITE],[자산처리계정],[품목자산분류],[재고자산종류],[매출원가계정],[대분류],[중분류],[소분류],[품목기타분류],[품명],[품번],[규격],[단위],[기초수량],[기초금액],[입고수량],[입고금액],[출고수량],[출고금액],[재고수량A],[결산재고수량B],[차이수량A_B],[재고금액C],[결산재고금액D],[차이금액C_D],[최종결산월재고단가],[생산수량],[생산금액],[구매수량],[구매금액],[적송입고수량],[적송입고금액],[기타입고수량],[기타입고금액],[판매수량],[판매원가],[투입수량],[투입금액],[적송출고수량],[적송출고금액],[기타출고수량],[기타출고금액])
SELECT m.[YYYYMM],m.[SEL_CODE],m.[SITE],m.[자산처리계정],m.[품목자산분류],m.[재고자산종류],m.[매출원가계정],m.[대분류],m.[중분류],m.[소분류],m.[품목기타분류],m.[품명],m.[품번],m.[규격],m.[단위],m.[기초수량],m.[기초금액],m.[입고수량],m.[입고금액],m.[출고수량],m.[출고금액],m.[재고수량],m.[결산후재고수량],m.[차이수량],m.[재고금액],m.[결산후재고금액],m.[차이금액],m.[최종결산월재고단가],m.[생산수량],m.[생산금액],m.[구매수량],m.[구매금액],m.[적송입고수량],m.[적송입고금액],m.[기타입고수량],m.[기타입고금액],m.[판매수량],m.[판매원가],m.[투입수량],m.[투입금액],m.[적송출고수량],m.[적송출고금액],m.[기타출고수량],m.[기타출고금액]
  FROM DOI_MATL_RESC m
 WHERE m.YYYYMM='202608' AND m.SITE='HQ' AND m.SEL_CODE='ACTUAL';

/* ---------- 검증 ---------- */
DECLARE @ok BIT = 1, @msg NVARCHAR(1000) = N'';
DECLARE @n INT = (SELECT COUNT(*) FROM DOI_IVDD WHERE YYYYMM='202608' AND SITE='HQ');
DECLARE @d INT = (SELECT COUNT(*) FROM DOI_MATL_RESC m
                   WHERE m.YYYYMM='202608' AND m.SITE='HQ'
                     AND NOT EXISTS (SELECT 1 FROM DOI_IVDD i
                                      WHERE i.YYYYMM=m.YYYYMM AND i.SITE=m.SITE AND i.품번=m.품번
                                        AND ABS(ISNULL(i.재고금액C,0)-ISNULL(m.재고금액,0))<=0.5));
IF @n <> 278 BEGIN SET @ok=0; SET @msg=@msg+N'행수 278 기대, 실제 '+CAST(@n AS NVARCHAR(10))+N'; '; END
IF @d <> 0   BEGIN SET @ok=0; SET @msg=@msg+N'MATL_RESC 와 금액 대조 불일치 '+CAST(@d AS NVARCHAR(10))+N'행; '; END

IF @ok = 1
BEGIN
  COMMIT;
  SELECT N'DOI_IVDD 적재 완료' AS 결과, @before AS 삭제전, @n AS 적재행수,
         (SELECT SUM(재고금액C) FROM DOI_IVDD WHERE YYYYMM='202608') AS 재고금액,
         (SELECT SUM(기초금액)   FROM DOI_IVDD WHERE YYYYMM='202608') AS 기초금액;
END
ELSE
BEGIN
  ROLLBACK;
  SELECT N'DOI_IVDD 검증 실패 - 원상복구' AS 결과, @msg AS 사유;
END
GO
