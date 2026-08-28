-- ⚠️운영(도우제조원가시스템) 배포용. dev(DWCMSTEST) 라이브 정의에서 추출(2026-08-28).
-- 검토 후 운영에서 실행. 멱등(존재시 스킵/ALTER).

-- DOI_ACCT_VN(계정 다국어 마스터) 시드. 운영=0행 → DEPT_COST 계정과목(ACCT_KO) 무산출 방지.
-- 동일 서버라 dev(DWCMSTEST)에서 직접 복사. ★운영 DOI_ACCT_VN 이 비어있을 때만 실행 권장.
IF NOT EXISTS (SELECT 1 FROM dbo.DOI_ACCT_VN)
    INSERT INTO dbo.DOI_ACCT_VN (ACCT_NAME, ACCT, ACCT_KO, ACCT_EN, ACCT_JP, ACCT_CN, ACCT_TW, ACCT_VN, 상위계정과목, 원가구분)
    SELECT ACCT_NAME, ACCT, ACCT_KO, ACCT_EN, ACCT_JP, ACCT_CN, ACCT_TW, ACCT_VN, 상위계정과목, 원가구분
    FROM DWCMSTEST.dbo.DOI_ACCT_VN;
GO
-- 확인: SELECT COUNT(*), SUM(CASE WHEN ISNULL(ACCT_KO,'')<>'' THEN 1 ELSE 0 END) FROM dbo.DOI_ACCT_VN;
