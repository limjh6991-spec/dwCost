/* ============================================================
   매출원가 체크(C0003011) 메뉴 숨김 처리 (260801)
   사유: /c0003011 라우트·컴포넌트·매퍼 미구현 상태로 메뉴만 존재 → 클릭 시 빈 화면
         (MenuTabs: "경로 /c0003011가 라우터에 등록되어 있지 않습니다")
   대상: HQ·VN 공용 메뉴 → prod_category 무관 전체 숨김
   ============================================================ */
UPDATE DOI_CM_SYS_RESOURCE
   SET DEL_YN='Y', MODI_DT=getdate(), MODI_USER='SYSADMIN'
 WHERE SYS_RESOURCE_ID='C0003011';

-- 확인
-- SELECT prod_category, SYS_RESOURCE_ID, SYS_RESOURCE_NAME, URL, DEL_YN FROM DOI_CM_SYS_RESOURCE WHERE SYS_RESOURCE_ID='C0003011';
