/* ============================================================
   기준정보 > 제품 코드(C0001006) · 일반 코드(C0001007) 메뉴 숨김 (260801)
   대상: HQ·VN 공용 → prod_category 무관 전체 숨김
   결과: 기준정보 활성 메뉴 = 원가기준정보(C0001004), 사용자-메뉴 권한 관리(C0001009)
   ============================================================ */
UPDATE DOI_CM_SYS_RESOURCE
   SET DEL_YN='Y', MODI_DT=getdate(), MODI_USER='SYSADMIN'
 WHERE SYS_RESOURCE_ID IN ('C0001006','C0001007');

-- 확인
-- SELECT prod_category, SYS_RESOURCE_ID, SYS_RESOURCE_NAME, DEL_YN
--   FROM DOI_CM_SYS_RESOURCE WHERE UPPER_SYS_RESOURCE_ID='C0001000' ORDER BY prod_category, SEQ;
