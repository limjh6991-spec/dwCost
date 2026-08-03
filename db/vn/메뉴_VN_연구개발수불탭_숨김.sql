/* ============================================================
   비나법인(VN) 타시스템 I/F&Upload > 생산정보 > 연구개발 수불(TAB070002) 탭 숨김 (260801)
   대상: VN 전용 (HQ는 유지)
   결과: VN 생산정보(C0007003) 활성 탭 = 생산수불(TAB070001) 만
   ============================================================ */
UPDATE DOI_CM_SYS_RESOURCE
   SET DEL_YN='Y', MODI_DT=getdate(), MODI_USER='SYSADMIN'
 WHERE prod_category='VN' AND SYS_RESOURCE_ID='TAB070002';

-- 확인
-- SELECT SYS_RESOURCE_ID, SYS_RESOURCE_NAME, DEL_YN FROM DOI_CM_SYS_RESOURCE
--  WHERE prod_category='VN' AND UPPER_SYS_RESOURCE_ID='C0007003' ORDER BY SEQ;
