-- =============================================================================
-- 메뉴 시드 : 타시스템 I/F&Upload > 기타입출고금액 (본사)
--   화면 C0007017 → /c0007017 → DOI_ETC_INOUT
--   멱등: 이미 있으면 건너뛴다.
-- =============================================================================

-- 1) 메뉴 등록 (HQ)
IF NOT EXISTS (SELECT 1 FROM DOI_CM_SYS_RESOURCE
               WHERE prod_category = 'HQ' AND SYS_RESOURCE_ID = 'C0007017')
BEGIN
    INSERT INTO DOI_CM_SYS_RESOURCE
        (prod_category, SYS_RESOURCE_ID, SYS_RESOURCE_NAME, UPPER_SYS_RESOURCE_ID,
         SYS_RESOURCE_TYPE_CODE_ID, DESCRIPTION, SEQ, URL, INIT_DT, INIT_USER, DEL_YN)
    VALUES
        ('HQ', 'C0007017', N'기타입출고금액', 'C0007000',
         'MENU', N'ERP 기타입출고금액조회(통합) - DOI_ETC_INOUT', 12, '/c0007017', GETDATE(), 'SYSADMIN', 'N');
END
GO

-- 2) 역할 매핑 (상위 메뉴 C0007000 을 이미 가진 역할과 동일하게)
INSERT INTO doi_cm_role_sys_resource
    (ROLE_ID, prod_category, UPPER_SYS_RESOURCE_ID, SYS_RESOURCE_ID, SYS_RESOURCE_TYPE_CODE_ID, INIT_DT, INIT_USER)
SELECT r.ROLE_ID, 'HQ', 'C0007000', 'C0007017', 'MENU', GETDATE(), 'SYSADMIN'
FROM doi_cm_role_sys_resource r
WHERE r.prod_category = 'HQ'
  AND r.SYS_RESOURCE_ID = 'C0007000'
  AND NOT EXISTS (SELECT 1 FROM doi_cm_role_sys_resource x
                  WHERE x.ROLE_ID = r.ROLE_ID
                    AND x.prod_category = 'HQ'
                    AND x.SYS_RESOURCE_ID = 'C0007017');
GO
