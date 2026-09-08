/* =====================================================================
 * [VN 화면] 인터페이스 탭 3종 추가 + TAB070004 이름 정정
 *   신규 탭은 기존 형제 탭 행을 복제(TYPE_CODE/prod_category 상속) + SEQ를 형제 사이로 시프트.
 *   멱등(NOT EXISTS). 각 prod_category(VN·HQ 등) 모두 대상(형제가 존재하는 카테고리만).
 *   ⚠️ 역할 권한(doi_cm_role_sys_resource)은 [C0001009 역할-메뉴 권한 트리] 화면에서 부여 권장
 *      (하단 [4] 복제 SQL은 참고용 — 실제 컬럼 확인 후 사용).
 *   실행: DWCMSTEST (SSMS)
 * ===================================================================== */
SET NOCOUNT ON;

/* ===== [1] 언어별계정항목(TAB010006): 계정코드(TAB010001) 바로 다음 (C0001004 하위) ===== */
UPDATE r SET r.SEQ = r.SEQ + 1
FROM DOI_CM_SYS_RESOURCE r
JOIN DOI_CM_SYS_RESOURCE b ON b.prod_category=r.prod_category AND b.SYS_RESOURCE_ID='TAB010001' AND b.DEL_YN='N'
WHERE r.UPPER_SYS_RESOURCE_ID='C0001004' AND r.DEL_YN='N' AND r.SEQ > b.SEQ;

INSERT INTO DOI_CM_SYS_RESOURCE (prod_category, SYS_RESOURCE_ID, SYS_RESOURCE_NAME, UPPER_SYS_RESOURCE_ID, SYS_RESOURCE_TYPE_CODE_ID, DESCRIPTION, SEQ, URL, INIT_DT, INIT_USER, DEL_YN)
SELECT s.prod_category, N'TAB010006', N'언어별계정항목', s.UPPER_SYS_RESOURCE_ID, s.SYS_RESOURCE_TYPE_CODE_ID, N'언어별계정항목(ACCLANG)', s.SEQ+1, s.URL, GETDATE(), s.INIT_USER, 'N'
FROM DOI_CM_SYS_RESOURCE s
WHERE s.SYS_RESOURCE_ID='TAB010001' AND s.UPPER_SYS_RESOURCE_ID='C0001004' AND s.DEL_YN='N'
  AND NOT EXISTS (SELECT 1 FROM DOI_CM_SYS_RESOURCE x WHERE x.SYS_RESOURCE_ID='TAB010006' AND x.prod_category=s.prod_category);

/* ===== [2] 공정(TAB010007): 자재코드(TAB010003) 바로 다음 (면적기준정보 TAB010004 앞) ===== */
UPDATE r SET r.SEQ = r.SEQ + 1
FROM DOI_CM_SYS_RESOURCE r
JOIN DOI_CM_SYS_RESOURCE b ON b.prod_category=r.prod_category AND b.SYS_RESOURCE_ID='TAB010003' AND b.DEL_YN='N'
WHERE r.UPPER_SYS_RESOURCE_ID='C0001004' AND r.DEL_YN='N' AND r.SEQ > b.SEQ;

INSERT INTO DOI_CM_SYS_RESOURCE (prod_category, SYS_RESOURCE_ID, SYS_RESOURCE_NAME, UPPER_SYS_RESOURCE_ID, SYS_RESOURCE_TYPE_CODE_ID, DESCRIPTION, SEQ, URL, INIT_DT, INIT_USER, DEL_YN)
SELECT s.prod_category, N'TAB010007', N'공정', s.UPPER_SYS_RESOURCE_ID, s.SYS_RESOURCE_TYPE_CODE_ID, N'공정(PROCESS)', s.SEQ+1, s.URL, GETDATE(), s.INIT_USER, 'N'
FROM DOI_CM_SYS_RESOURCE s
WHERE s.SYS_RESOURCE_ID='TAB010003' AND s.UPPER_SYS_RESOURCE_ID='C0001004' AND s.DEL_YN='N'
  AND NOT EXISTS (SELECT 1 FROM DOI_CM_SYS_RESOURCE x WHERE x.SYS_RESOURCE_ID='TAB010007' AND x.prod_category=s.prod_category);

/* ===== [3] 수출신고필증조회(TAB070024): 수출매출품목조회(TAB070004) 바로 다음 (수출Claim TAB070016 앞) ===== */
UPDATE r SET r.SEQ = r.SEQ + 1
FROM DOI_CM_SYS_RESOURCE r
JOIN DOI_CM_SYS_RESOURCE b ON b.prod_category=r.prod_category AND b.SYS_RESOURCE_ID='TAB070004' AND b.DEL_YN='N'
WHERE r.UPPER_SYS_RESOURCE_ID='C0007005' AND r.DEL_YN='N' AND r.SEQ > b.SEQ;

INSERT INTO DOI_CM_SYS_RESOURCE (prod_category, SYS_RESOURCE_ID, SYS_RESOURCE_NAME, UPPER_SYS_RESOURCE_ID, SYS_RESOURCE_TYPE_CODE_ID, DESCRIPTION, SEQ, URL, INIT_DT, INIT_USER, DEL_YN)
SELECT s.prod_category, N'TAB070024', N'수출신고필증조회', s.UPPER_SYS_RESOURCE_ID, s.SYS_RESOURCE_TYPE_CODE_ID, N'수출신고필증조회(EXP_PERMIT)', s.SEQ+1, s.URL, GETDATE(), s.INIT_USER, 'N'
FROM DOI_CM_SYS_RESOURCE s
WHERE s.SYS_RESOURCE_ID='TAB070004' AND s.UPPER_SYS_RESOURCE_ID='C0007005' AND s.DEL_YN='N'
  AND NOT EXISTS (SELECT 1 FROM DOI_CM_SYS_RESOURCE x WHERE x.SYS_RESOURCE_ID='TAB070024' AND x.prod_category=s.prod_category);

/* ===== [E] TAB070004 이름 정정: (수출신고필증 오기) → 수출매출품목조회 ===== */
UPDATE DOI_CM_SYS_RESOURCE SET SYS_RESOURCE_NAME = N'수출매출품목조회'
WHERE SYS_RESOURCE_ID='TAB070004' AND DEL_YN='N';

/* ===== [4] (참고) 역할 권한 복제 — 형제 탭 권한을 신규 탭에 복사. 실제 컬럼 확인 후 사용 =====
INSERT INTO doi_cm_role_sys_resource (role_id, sys_resource_id, prod_category)
SELECT role_id, N'TAB010006', prod_category FROM doi_cm_role_sys_resource WHERE sys_resource_id='TAB010001'
  AND NOT EXISTS (SELECT 1 FROM doi_cm_role_sys_resource y WHERE y.sys_resource_id='TAB010006' AND y.role_id=doi_cm_role_sys_resource.role_id AND y.prod_category=doi_cm_role_sys_resource.prod_category);
-- TAB010007 ← TAB010003, TAB070024 ← TAB070004 동일 패턴
*/

/* ===== 검증 ===== */
SELECT UPPER_SYS_RESOURCE_ID, prod_category, SYS_RESOURCE_ID, SYS_RESOURCE_NAME, SEQ
FROM DOI_CM_SYS_RESOURCE
WHERE UPPER_SYS_RESOURCE_ID IN ('C0001004','C0007005') AND DEL_YN='N'
ORDER BY UPPER_SYS_RESOURCE_ID, prod_category, SEQ;
