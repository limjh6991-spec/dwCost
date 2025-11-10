-- =====================================================
-- 생산수불 자체 체크 메뉴 등록 (100% 정확한 버전)
-- 타시스템 I/F & Upload (C0007000) 하위에 생산정보(C0007003) 다음에 추가
-- =====================================================

-- 1. 기존 메뉴 순서 증가 (C0007004 이후 메뉴들의 SEQ를 1씩 증가)
UPDATE DOI_CM_SYS_RESOURCE 
SET SEQ = SEQ + 1
WHERE UPPER_SYS_RESOURCE_ID = 'C0007000'
  AND prod_category = 'COST'
  AND del_yn = 'N'
  AND SEQ >= (
    SELECT SEQ + 1
    FROM DOI_CM_SYS_RESOURCE
    WHERE SYS_RESOURCE_ID = 'C0007003'
      AND UPPER_SYS_RESOURCE_ID = 'C0007000'
      AND prod_category = 'COST'
  );

-- 2. 새 메뉴 등록
INSERT INTO DOI_CM_SYS_RESOURCE (
    prod_category,
    SYS_RESOURCE_ID,
    SYS_RESOURCE_NAME,
    UPPER_SYS_RESOURCE_ID,
    SYS_RESOURCE_TYPE_CODE_ID,
    DESCRIPTION,
    SEQ,
    URL,
    INIT_DT,
    INIT_USER,
    DEL_YN
)
SELECT
    'COST' AS prod_category,
    'C0009001' AS SYS_RESOURCE_ID,
    N'생산수불 자체 체크' AS SYS_RESOURCE_NAME,
    'C0007000' AS UPPER_SYS_RESOURCE_ID,
    'M' AS SYS_RESOURCE_TYPE_CODE_ID,
    N'생산정보 무결성 검증 및 수량 밸런스 체크' AS DESCRIPTION,
    (SELECT SEQ + 1 
     FROM DOI_CM_SYS_RESOURCE 
     WHERE SYS_RESOURCE_ID = 'C0007003' 
       AND UPPER_SYS_RESOURCE_ID = 'C0007000'
       AND prod_category = 'COST') AS SEQ,
    '/c0009001' AS URL,
    GETDATE() AS INIT_DT,
    'ADMIN' AS INIT_USER,
    'N' AS DEL_YN
WHERE NOT EXISTS (
    SELECT 1 
    FROM DOI_CM_SYS_RESOURCE 
    WHERE SYS_RESOURCE_ID = 'C0009001'
      AND prod_category = 'COST'
);

-- 3. 메뉴 권한 설정 (모든 역할에 권한 부여)
-- ROLE_ADMIN 권한
INSERT INTO doi_cm_role_sys_resource (
    ROLE_ID,
    PROD_CATEGORY,
    UPPER_SYS_RESOURCE_ID,
    SYS_RESOURCE_ID,
    SYS_RESOURCE_TYPE_CODE_ID,
    INIT_DT,
    INIT_USER
)
SELECT
    'ROLE_ADMIN' AS ROLE_ID,
    'COST' AS PROD_CATEGORY,
    'C0007000' AS UPPER_SYS_RESOURCE_ID,
    'C0009001' AS SYS_RESOURCE_ID,
    'M' AS SYS_RESOURCE_TYPE_CODE_ID,
    GETDATE() AS INIT_DT,
    'ADMIN' AS INIT_USER
WHERE NOT EXISTS (
    SELECT 1 
    FROM doi_cm_role_sys_resource 
    WHERE ROLE_ID = 'ROLE_ADMIN' 
      AND SYS_RESOURCE_ID = 'C0009001'
      AND PROD_CATEGORY = 'COST'
);

-- =====================================================
-- 확인 쿼리
-- =====================================================

-- 4. C0007000 하위 메뉴 전체 확인 (순서대로)
SELECT 
    SR.SEQ,
    SR.SYS_RESOURCE_ID,
    SR.SYS_RESOURCE_NAME,
    SR.UPPER_SYS_RESOURCE_ID,
    SR.URL,
    SR.DEL_YN,
    SR.DESCRIPTION
FROM DOI_CM_SYS_RESOURCE SR
WHERE SR.UPPER_SYS_RESOURCE_ID = 'C0007000'
  AND SR.prod_category = 'COST'
  AND SR.del_yn = 'N'
ORDER BY SR.SEQ;

-- 5. 신규 메뉴 확인
SELECT 
    *
FROM DOI_CM_SYS_RESOURCE
WHERE SYS_RESOURCE_ID = 'C0009001'
  AND prod_category = 'COST';

-- 6. 권한 확인
SELECT 
    RR.ROLE_ID,
    RR.PROD_CATEGORY,
    SR.SYS_RESOURCE_ID,
    SR.SYS_RESOURCE_NAME,
    SR.URL
FROM doi_cm_role_sys_resource RR
JOIN DOI_CM_SYS_RESOURCE SR 
  ON RR.SYS_RESOURCE_ID = SR.SYS_RESOURCE_ID
  AND RR.PROD_CATEGORY = SR.prod_category
WHERE SR.SYS_RESOURCE_ID = 'C0009001'
  AND RR.PROD_CATEGORY = 'COST';
