/* HQ 인터페이스 스테이징 (DOI_VN_IF_* 미러, SITE='HQ'로 적재) — 코드/구조만, 2026-08-24 */

IF OBJECT_ID('DOI_HQ_IF_ACCOUNT') IS NULL
CREATE TABLE DOI_HQ_IF_ACCOUNT (
    [SITE] nvarchar(4) NOT NULL,
    [LOAD_DTTM] datetime NOT NULL,
    [REQUEST_ID] nvarchar(50) NULL,
    [SMAccKind] nvarchar(100) NULL,
    [AccSeq] int NULL,
    [AccNo] nvarchar(100) NULL,
    [DualAccNo] nvarchar(100) NULL,
    [AccName] nvarchar(100) NULL,
    [SMAccKindName] nvarchar(100) NULL,
    [AccLevel] int NULL,
    [UpperAccName] nvarchar(100) NULL,
    [UpperAccSeq] int NULL,
    [TreeSort] int NULL,
    [AccSort] int NULL,
    [RAW_JSON] nvarchar(MAX) NULL
);

IF OBJECT_ID('DOI_HQ_IF_DEPT_COST') IS NULL
CREATE TABLE DOI_HQ_IF_DEPT_COST (
    [SITE] nvarchar(4) NOT NULL,
    [SEL_CODE] nvarchar(10) NULL,
    [LOAD_DTTM] datetime NOT NULL,
    [REQUEST_ID] nvarchar(50) NULL,
    [CCtrName] nvarchar(100) NULL,
    [DeptSeq] int NULL,
    [AccNameCost] nvarchar(100) NULL,
    [AccNo] nvarchar(100) NULL,
    [AccName] nvarchar(100) NULL,
    [UMCostTypeName] nvarchar(100) NULL,
    [AccSeq] int NULL,
    [DrAmt] decimal NULL,
    [CrAmt] decimal NULL,
    [RAW_JSON] nvarchar(MAX) NULL
);

