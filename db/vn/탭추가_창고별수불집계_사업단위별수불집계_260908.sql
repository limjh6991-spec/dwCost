/* =====================================================================
 * [VN 화면] 자재투입정보(C0007016)에 인터페이스 탭 2종 추가
 *   창고별수불집계조회(TAB070025) / 사업단위별수불집계조회(TAB070026)
 *   순서: 자재조회(TAB070023) 바로 다음.
 *   신규 탭은 기존 형제 탭 행을 복제(TYPE_CODE/prod_category/URL 상속) + SEQ 시프트.
 *   멱등(NOT EXISTS). 형제가 존재하는 prod_category(VN 등)만 자동 대상.
 *   ⚠️ 역할 권한(doi_cm_role_sys_resource)은 [C0001009 역할-메뉴 권한 트리] 화면에서 부여 권장.
 *   실행: DWCMSTEST (SSMS)
 * ===================================================================== */
SET NOCOUNT ON;

/* ===== [1] 창고별수불집계조회(TAB070025): 자재조회(TAB070023) 바로 다음 (C0007016 하위) ===== */
UPDATE r SET r.SEQ = r.SEQ + 1
FROM DOI_CM_SYS_RESOURCE r
JOIN DOI_CM_SYS_RESOURCE b ON b.prod_category=r.prod_category AND b.SYS_RESOURCE_ID='TAB070023' AND b.DEL_YN='N'
WHERE r.UPPER_SYS_RESOURCE_ID='C0007016' AND r.DEL_YN='N' AND r.SEQ > b.SEQ;

INSERT INTO DOI_CM_SYS_RESOURCE (prod_category, SYS_RESOURCE_ID, SYS_RESOURCE_NAME, UPPER_SYS_RESOURCE_ID, SYS_RESOURCE_TYPE_CODE_ID, DESCRIPTION, SEQ, URL, INIT_DT, INIT_USER, DEL_YN)
SELECT s.prod_category, N'TAB070025', N'창고별수불집계조회', s.UPPER_SYS_RESOURCE_ID, s.SYS_RESOURCE_TYPE_CODE_ID, N'창고별수불집계조회(WH_STOCK_SUM)', s.SEQ+1, s.URL, GETDATE(), s.INIT_USER, 'N'
FROM DOI_CM_SYS_RESOURCE s
WHERE s.SYS_RESOURCE_ID='TAB070023' AND s.UPPER_SYS_RESOURCE_ID='C0007016' AND s.DEL_YN='N'
  AND NOT EXISTS (SELECT 1 FROM DOI_CM_SYS_RESOURCE x WHERE x.SYS_RESOURCE_ID='TAB070025' AND x.prod_category=s.prod_category);

/* ===== [2] 사업단위별수불집계조회(TAB070026): 창고별수불집계조회(TAB070025) 바로 다음 ===== */
UPDATE r SET r.SEQ = r.SEQ + 1
FROM DOI_CM_SYS_RESOURCE r
JOIN DOI_CM_SYS_RESOURCE b ON b.prod_category=r.prod_category AND b.SYS_RESOURCE_ID='TAB070025' AND b.DEL_YN='N'
WHERE r.UPPER_SYS_RESOURCE_ID='C0007016' AND r.DEL_YN='N' AND r.SEQ > b.SEQ;

INSERT INTO DOI_CM_SYS_RESOURCE (prod_category, SYS_RESOURCE_ID, SYS_RESOURCE_NAME, UPPER_SYS_RESOURCE_ID, SYS_RESOURCE_TYPE_CODE_ID, DESCRIPTION, SEQ, URL, INIT_DT, INIT_USER, DEL_YN)
SELECT s.prod_category, N'TAB070026', N'사업단위별수불집계조회', s.UPPER_SYS_RESOURCE_ID, s.SYS_RESOURCE_TYPE_CODE_ID, N'사업단위별수불집계조회(BIZ_STOCK_SUM)', s.SEQ+1, s.URL, GETDATE(), s.INIT_USER, 'N'
FROM DOI_CM_SYS_RESOURCE s
WHERE s.SYS_RESOURCE_ID='TAB070025' AND s.UPPER_SYS_RESOURCE_ID='C0007016' AND s.DEL_YN='N'
  AND NOT EXISTS (SELECT 1 FROM DOI_CM_SYS_RESOURCE x WHERE x.SYS_RESOURCE_ID='TAB070026' AND x.prod_category=s.prod_category);

/* ===== [3] (참고) 역할 권한 복제 — 형제 탭 권한을 신규 탭에 복사. 실제 컬럼 확인 후 사용 =====
INSERT INTO doi_cm_role_sys_resource (role_id, sys_resource_id, prod_category)
SELECT role_id, N'TAB070025', prod_category FROM doi_cm_role_sys_resource WHERE sys_resource_id='TAB070023'
  AND NOT EXISTS (SELECT 1 FROM doi_cm_role_sys_resource y WHERE y.sys_resource_id='TAB070025' AND y.role_id=doi_cm_role_sys_resource.role_id AND y.prod_category=doi_cm_role_sys_resource.prod_category);
-- TAB070026 ← TAB070025 동일 패턴
*/

/* ===== 검증 ===== */
SELECT UPPER_SYS_RESOURCE_ID, prod_category, SYS_RESOURCE_ID, SYS_RESOURCE_NAME, SEQ
FROM DOI_CM_SYS_RESOURCE
WHERE UPPER_SYS_RESOURCE_ID = 'C0007016' AND DEL_YN='N'
ORDER BY prod_category, SEQ;
