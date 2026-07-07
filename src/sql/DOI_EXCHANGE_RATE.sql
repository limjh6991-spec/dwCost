/* =====================================================================
 * 환율 마스터 (월평균) - VINA USD → KRW/VND 화면 환산 기준
 *   메뉴: c0007000 출하/매출·생산 화면군 공용
 *   역할: 담당자가 월별 월평균 환율을 수동 입력 → 화면 환산에 사용
 *   사용: C0007012.xml (환율관리 팝업=수동 입력/수정, C0007012_Rate=화면 조회)
 *   의미: 환율 = "USD 1 = N 통화"  (예: 통화='KRW', 환율=1350.0000)
 *         화면 표시금액 = DB저장 USD금액 × 환율
 *   등록자: 입력한 사용자ID
 *   운영/개발 DB(MS SQL Server)에 1회 실행.
 * ===================================================================== */
IF OBJECT_ID(N'dbo.DOI_EXCHANGE_RATE', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.DOI_EXCHANGE_RATE (
        YYYYMM   varchar(6)  COLLATE Korean_Wansung_CI_AS NOT NULL,  -- 기준월 (예: 202605)
        통화     varchar(3)  COLLATE Korean_Wansung_CI_AS NOT NULL,  -- KRW / VND
        환율     numeric(18,4) NOT NULL,                              -- USD 1 = N 통화 (월평균)
        등록자   varchar(30) COLLATE Korean_Wansung_CI_AS NULL,
        등록일시 datetime     NULL,
        CONSTRAINT PK_DOI_EXCHANGE_RATE PRIMARY KEY (YYYYMM, 통화)
    );
END
GO
