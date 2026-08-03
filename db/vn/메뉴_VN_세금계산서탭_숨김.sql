/* ============================================================
   비나법인(VN) 타시스템 I/F&Upload > 매출정보 > 세금계산서(TAB070003) 탭 숨김 (260801)
   대상: VN 전용 (HQ는 유지)
   결과: VN 매출정보(C0007005) 활성 탭 = 수출신고필증(TAB070004) 만
   ============================================================ */
UPDATE DOI_CM_SYS_RESOURCE
   SET DEL_YN='Y', MODI_DT=getdate(), MODI_USER='SYSADMIN'
 WHERE prod_category='VN' AND SYS_RESOURCE_ID='TAB070003';

-- 확인
-- SELECT SYS_RESOURCE_ID, SYS_RESOURCE_NAME, DEL_YN FROM DOI_CM_SYS_RESOURCE
--  WHERE prod_category='VN' AND UPPER_SYS_RESOURCE_ID='C0007005' ORDER BY SEQ;
