/* ============================================================
   비나법인(VN) 매출상계 탭(TAB030020) 숨김 처리 (260801)
   사유: 매출상계(UP_DOI_SCOF)는 본사(HQ) 전용, VN 미사용 → VN 매출원가집계(C0003002)에서 탭 제거
   결과: VN C0003002 활성 탭 = TAB030018(제품수불), TAB030019(매출원가·판관비) 2개만 유지
   ============================================================ */
UPDATE DOI_CM_SYS_RESOURCE
   SET DEL_YN='Y', MODI_DT=getdate(), MODI_USER='SYSADMIN'
 WHERE prod_category='VN' AND SYS_RESOURCE_ID='TAB030020';

-- 확인
-- SELECT SEQ,SYS_RESOURCE_ID,SYS_RESOURCE_NAME,DEL_YN FROM DOI_CM_SYS_RESOURCE
--  WHERE prod_category='VN' AND UPPER_SYS_RESOURCE_ID='C0003002' ORDER BY SEQ;
