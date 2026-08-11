-- VN ERP/MES → CMS 인터페이스 스테이징 테이블 (2차 마스터 5종) [DWCMSTEST/VN]
-- 방식B: CMS=O(또는 마스터 전체) 필드 + 공통 + RAW_JSON. 적재=조회조건 기준 삭제후 재적재

IF OBJECT_ID(N'DOI_VN_IF_ACCOUNT',N'U') IS NULL
CREATE TABLE DOI_VN_IF_ACCOUNT (
    SITE        NVARCHAR(4)    NOT NULL DEFAULT N'VN',
    LOAD_DTTM   DATETIME       NOT NULL DEFAULT GETDATE(),
    REQUEST_ID  NVARCHAR(50)   NULL,
    SMAccKind                          NVARCHAR(100)    NULL,  -- 계정대분류내부코드
    AccSeq                             INT              NULL,  -- 계정내부코드
    AccNo                              NVARCHAR(100)    NULL,  -- 계정코드
    DualAccNo                          NVARCHAR(100)    NULL,  -- 보조계정코드
    AccName                            NVARCHAR(100)    NULL,  -- 계정과목명
    SMAccKindName                      NVARCHAR(100)    NULL,  -- 계정대분류
    AccLevel                           INT              NULL,  -- 계정레벨
    UpperAccName                       NVARCHAR(100)    NULL,  -- 상위계정과목
    UpperAccSeq                        INT              NULL,  -- 상위계정과목내부코드
    TreeSort                           INT              NULL,  -- Tree 구조의 순서
    AccSort                            INT              NULL,  -- 조회순서
    RAW_JSON    NVARCHAR(MAX)  NULL
);
-- [계정코드] 11 데이터컬럼 + 공통3 + RAW_JSON

IF OBJECT_ID(N'DOI_VN_IF_DEPT',N'U') IS NULL
CREATE TABLE DOI_VN_IF_DEPT (
    SITE        NVARCHAR(4)    NOT NULL DEFAULT N'VN',
    LOAD_DTTM   DATETIME       NOT NULL DEFAULT GETDATE(),
    REQUEST_ID  NVARCHAR(50)   NULL,
    DeptName                           NVARCHAR(100)    NULL,  -- 부서명
    EngDeptName                        NVARCHAR(100)    NULL,  -- 영문부서명
    BegDate                            NCHAR(8)         NULL,  -- 시작일
    EndDate                            NCHAR(8)         NULL,  -- 종료일
    BizUnit                            NCHAR(1)         NULL,  -- 사업자번호내부코드 (CÔNG TY TNHH DOWOOINSYS VINA)
    FactUnit                           NCHAR(1)         NULL,  -- 사업단위내부코드 (DOWOO VINA)
    Remark                             NVARCHAR(1000)   NULL,  -- 비고
    IsUse                              NCHAR(1)         NULL,  -- 사용여부
    CCtrName                           NVARCHAR(100)    NULL,  -- 코스트센터
    UMDeptAttrName                     NVARCHAR(100)    NULL,  -- 부서레벨
    Email                              NVARCHAR(100)    NULL,  -- 이메일
    RAW_JSON    NVARCHAR(MAX)  NULL
);
-- [부서코드] 11 데이터컬럼 + 공통3 + RAW_JSON

IF OBJECT_ID(N'DOI_VN_IF_MATERIAL',N'U') IS NULL
CREATE TABLE DOI_VN_IF_MATERIAL (
    SITE        NVARCHAR(4)    NOT NULL DEFAULT N'VN',
    LOAD_DTTM   DATETIME       NOT NULL DEFAULT GETDATE(),
    REQUEST_ID  NVARCHAR(50)   NULL,
    ItemSeq                            INT              NULL,  -- 자재내부코드
    ItemName                           NVARCHAR(100)    NULL,  -- 자재명
    ItemNo                             NVARCHAR(100)    NULL,  -- 자재번호
    Spec                               NVARCHAR(100)    NULL,  -- 자재규격
    AssetName                          NVARCHAR(100)    NULL,  -- 품목자산분류
    UnitName                           NVARCHAR(100)    NULL,  -- 단위
    SMABCName                          NVARCHAR(100)    NULL,  -- 중요도
    SMStatusName                       NVARCHAR(100)    NULL,  -- 상태
    SMInOutKindName                    NVARCHAR(100)    NULL,  -- 내외자구분
    DeptName                           NVARCHAR(100)    NULL,  -- 관리부서
    EmpName                            NVARCHAR(100)    NULL,  -- 담당자
    STDItemName                        NVARCHAR(100)    NULL,  -- 자재대표품명
    ItemEngName                        NVARCHAR(100)    NULL,  -- 자재영문명
    ItemClassLName                     NVARCHAR(100)    NULL,  -- 자재대분류
    ItemClassMName                     NVARCHAR(100)    NULL,  -- 자재중분류
    ItemClassSName                     NVARCHAR(100)    NULL,  -- 자재소분류
    RegUserSeq                         INT              NULL,  -- 최초등록자내부코드
    LastUserSeq                        INT              NULL,  -- 최종수정자내부코드
    RegDate                            NCHAR(8)         NULL,  -- 등록일
    LastDate                           NCHAR(8)         NULL,  -- 최종수정일
    IsSTDItem                          NVARCHAR(100)    NULL,  -- 대표품목여부
    IsSet                              NCHAR(1)         NULL,  -- 세트품여부
    IsQC                               NCHAR(1)         NULL,  -- 품질검사여부
    SMOutKindName                      NVARCHAR(100)    NULL,  -- 출고구분여부
    IsBOMReg                           NCHAR(1)         NULL,  -- BOM등록여부
    IsProcMat                          NCHAR(1)         NULL,  -- 제품별공정소요자재
    SMLimitTermKindName                NVARCHAR(100)    NULL,  -- 유통기간구분
    SMLimitTermKind                    NVARCHAR(100)    NULL,  -- 유통기간
    IsLotMng                           NCHAR(1)         NULL,  -- Lot관리여부
    IsSerialMng                        NCHAR(1)         NULL,  -- Serial관리여부
    SMAssetGrp                         NCHAR(1)         NULL,  -- SMAssetGrp
    PurCustName                        NVARCHAR(100)    NULL,  -- 기본구매처
    TrustCustName                      NVARCHAR(100)    NULL,  -- 수탁거래처
    Remark                             NVARCHAR(100)    NULL,  -- 특이사항
    SMVatKindName                      NVARCHAR(100)    NULL,  -- 부가세구분
    PriceInVat                         NCHAR(1)         NULL,  -- 판매단가에 부가세포함여부
    IsFileCheck                        NCHAR(1)         NULL,  -- 첨부파일
    IsImageCheck                       NCHAR(1)         NULL,  -- 이미지
    STDItemNo                          NVARCHAR(100)    NULL,  -- 자재대표품번
    STDItemSpec                        NVARCHAR(100)    NULL,  -- 자재대표규격
    MKCustName                         NVARCHAR(100)    NULL,  -- 제조사
    IsPrice                            NCHAR(1)         NULL,  -- 단가등록여부
    URL                                NVARCHAR(100)    NULL,  -- URL
    UMProperty                         INT              NULL,  -- 품목속성내부코드
    UMPropertyName                     NVARCHAR(100)    NULL,  -- 품목속성
    MAT_GRP_1                          NVARCHAR(20)     NULL,  -- MAT_GRP_1 - Production Type
    MAT_GRP_2                          NVARCHAR(50)     NULL,  -- MAT_GRP_2 - Raw Material Group
    MAT_GRP_4                          NVARCHAR(20)     NULL,  -- MAT_GRP_4 - MAT_QC_TYPE
    MAT_GRP_5                          NVARCHAR(20)     NULL,  -- MAT_GRP_5 - Spare
    MAT_GRP_6                          NVARCHAR(20)     NULL,  -- MAT_GRP_6 - Spare
    MAT_GRP_7                          NVARCHAR(20)     NULL,  -- MAT_GRP_7 - Spare
    MAT_GRP_8                          NVARCHAR(20)     NULL,  -- MAT_GRP_8 - Spare
    MAT_GRP_9                          NVARCHAR(20)     NULL,  -- MAT_GRP_9 - Spare
    MAT_GRP_10                         NVARCHAR(20)     NULL,  -- MAT_GRP_10 - Spare
    MAT_CMF_1                          NVARCHAR(20)     NULL,  -- MAT_CMF_1 - Model name
    MAT_CMF_2                          NVARCHAR(20)     NULL,  -- MAT_CMF_2 - Glass Cutting Qty
    MAT_CMF_3                          NVARCHAR(20)     NULL,  -- MAT_CMF_3 - 원장 사양
    MAT_CMF_4                          NVARCHAR(20)     NULL,  -- MAT_CMF_4 - 원장 두께(um)
    MAT_CMF_5                          NVARCHAR(20)     NULL,  -- MAT_CMF_5 - UTG 버전
    MAT_CMF_6                          NVARCHAR(20)     NULL,  -- MAT_CMF_6 - PF F Ver
    MAT_CMF_7                          NVARCHAR(20)     NULL,  -- MAT_CMF_7 - PF F Code
    MAT_CMF_8                          NVARCHAR(20)     NULL,  -- MAT_CMF_8 - PF B Ver
    MAT_CMF_9                          NVARCHAR(20)     NULL,  -- MAT_CMF_9 - PF B Code
    MAT_CMF_10                         NVARCHAR(20)     NULL,  -- MAT_CMF_10 - Tray Code
    MAT_CMF_11                         NVARCHAR(20)     NULL,  -- MAT_CMF_11 - 치수 장변(mm)
    MAT_CMF_12                         NVARCHAR(20)     NULL,  -- MAT_CMF_12 - 치수 단변(mm)
    MAT_CMF_13                         NVARCHAR(20)     NULL,  -- MAT_CMF_13 - 제품 두께(mm)
    MAT_CMF_14                         NVARCHAR(20)     NULL,  -- MAT_CMF_14 - 강화특성 CS(Mpa)
    MAT_CMF_15                         NVARCHAR(20)     NULL,  -- MAT_CMF_15 - 강화특성 DoL(um)
    MAT_CMF_16                         NVARCHAR(50)     NULL,  -- MAT_CMF_16 - 자재 SPEC
    MAT_CMF_17                         NVARCHAR(20)     NULL,  -- MAT_CMF_17 - 조달구분
    MAT_CMF_18                         NVARCHAR(20)     NULL,  -- MAT_CMF_18 - 최소불출수량
    MAT_CMF_19                         NVARCHAR(20)     NULL,  -- MAT_CMF_19 - 자동 차감 여부
    MAT_CMF_20                         NVARCHAR(20)     NULL,  -- MAT_CMF_20 - 사용자 정의 항목 20
    FIRST_FLOW                         NVARCHAR(20)     NULL,  -- FIRST_FLOW - 처음 플로우 순서 번호
    FIRST_FLOW_SEQ_NUM                 INT              NULL,  -- FIRST_FLOW_SEQ_NUM - 처음 플로우 순서 번호
    LAST_FLOW                          NVARCHAR(20)     NULL,  -- LAST_FLOW - 마지막 플로우
    LAST_FLOW_SEQ_NUM                  INT              NULL,  -- LAST_FLOW_SEQ_NUM - 마지막 플로우 순서 번호
    MFG_DEVISION                       NVARCHAR(20)     NULL,  -- MFG_DEVISION - 생산 주체
    SUBCONTRACT_FLAG                   NVARCHAR(20)     NULL,  -- SUBCONTRACT_FLAG - 외부 생산 여부
    BASE_MAT_ID                        NVARCHAR(20)     NULL,  -- BASE_MAT_ID - 제품의 Base 가 되는 제품
    VENDOR_ID                          NVARCHAR(20)     NULL,  -- VENDOR_ID - Vendor 명
    VENDOR_MAT_ID                      NVARCHAR(20)     NULL,  -- VENDOR_MAT_ID - Vendor 의 제품명
    CUSTOMER_ID                        NVARCHAR(20)     NULL,  -- CUSTOMER_ID - 제품을 주문한 고객명
    CUSTOMER_MAT_ID                    NVARCHAR(20)     NULL,  -- CUSTOMER_MAT_ID - 고객이 주문한 제품명
    BOM_SET_ID                         NVARCHAR(20)     NULL,  -- BOM_SET_ID - 제품의 BOM Set 명
    APPLY_START_TIME                   NVARCHAR(20)     NULL,  -- APPLY_START_TIME - 버전 적용이 시작한 시간
    APPLY_END_TIME                     NVARCHAR(20)     NULL,  -- APPLY_END_TIME - 버전 적용이 끝난 시간
    APPROVAL_FLAG                      NVARCHAR(20)     NULL,  -- APPROVAL_FLAG - Approval 여부
    APPROVAL_USER_ID                   NVARCHAR(20)     NULL,  -- APPROVAL_USER_ID - Approval을 발생시킨 사용자
    APPROVAL_TIME                      NVARCHAR(20)     NULL,  -- APPROVAL_TIME - Approval 발생 시간
    RELEASE_FLAG                       NVARCHAR(20)     NULL,  -- RELEASE_FLAG - Release 여부
    RELEASE_USER_ID                    NVARCHAR(20)     NULL,  -- RELEASE_USER_ID - Release를 발생시킨 사용자
    RELEASE_TIME                       NVARCHAR(20)     NULL,  -- RELEASE_TIME - Release 시간
    DEACTIVE_FLAG                      NVARCHAR(20)     NULL,  -- DEACTIVE_FLAG - 버전 만료 여부
    DEACTIVE_USER_ID                   NVARCHAR(20)     NULL,  -- DEACTIVE_USER_ID - Deactive 사용자
    DEACTIVE_TIME                      NVARCHAR(20)     NULL,  -- DEACTIVE_TIME - 버전 만료 시간
    MAT_SHORT_DESC                     NVARCHAR(20)     NULL,  -- MAT_SHORT_DESC - 제품 간략 Discription
    IQC_YN                             NVARCHAR(200)    NULL,  -- IQC YN?
    VENDOR                             NVARCHAR(50)     NULL,  -- VENDOR
    RAW_JSON    NVARCHAR(MAX)  NULL
);
-- [자재코드] 100 데이터컬럼 + 공통3 + RAW_JSON

IF OBJECT_ID(N'DOI_VN_IF_ITEM',N'U') IS NULL
CREATE TABLE DOI_VN_IF_ITEM (
    SITE        NVARCHAR(4)    NOT NULL DEFAULT N'VN',
    LOAD_DTTM   DATETIME       NOT NULL DEFAULT GETDATE(),
    REQUEST_ID  NVARCHAR(50)   NULL,
    ItemSeq                            INT              NULL,  -- 품목내부코드
    ItemName                           NVARCHAR(100)    NULL,  -- 품명
    ItemNo                             NVARCHAR(100)    NULL,  -- 품번
    Spec                               NVARCHAR(100)    NULL,  -- 규격
    TrunName                           NVARCHAR(100)    NULL,  -- TrunName
    AssetName                          NVARCHAR(100)    NULL,  -- 품목자산분류명
    AssetSeq                           INT              NULL,  -- 품목자산분류내부코드
    UnitName                           NVARCHAR(100)    NULL,  -- 단위
    UnitSeq                            INT              NULL,  -- 단위내부코드
    SMABC                              INT              NULL,  -- 중요도내부코드
    SMABCName                          NVARCHAR(100)    NULL,  -- 중요도내부코드
    SMStatus                           INT              NULL,  -- 품목상태내부코드
    SMStatusName                       NVARCHAR(100)    NULL,  -- 품목상태
    SMInOutKind                        INT              NULL,  -- 내외자구분내부코드
    SMInOutKindName                    NVARCHAR(100)    NULL,  -- 내외자구분
    DeptName                           NVARCHAR(100)    NULL,  -- 관리부서
    DeptSeq                            INT              NULL,  -- 관리부서내부코드
    EmpName                            NVARCHAR(100)    NULL,  -- 담당자
    EmpSeq                             INT              NULL,  -- 담당자내부코드
    STDItemName                        NVARCHAR(100)    NULL,  -- 대표품명
    STDItemSeq                         INT              NULL,  -- 대표품목내부코드
    ItemEngName                        NVARCHAR(100)    NULL,  -- 영문명
    ItemClassLName                     NVARCHAR(100)    NULL,  -- 품목대분류
    ItemClassMName                     NVARCHAR(100)    NULL,  -- 품목중분류
    ItemClassSName                     NVARCHAR(100)    NULL,  -- 품목소분류
    UMItemClass                        INT              NULL,  -- 품목소분류내부코드
    RegUser                            NVARCHAR(100)    NULL,  -- 등록자
    LastUser                           NVARCHAR(100)    NULL,  -- 최종수정자
    RegDate                            NCHAR(8)         NULL,  -- 등록일
    LastDate                           NCHAR(8)         NULL,  -- 최종수정일
    IsSTDItem                          NCHAR(1)         NULL,  -- 대표품목
    IsOption                           NCHAR(1)         NULL,  -- IsOption
    IsSet                              NCHAR(1)         NULL,  -- 세트품목
    IsQC                               NCHAR(1)         NULL,  -- 검사대상
    SMOutKindName                      NVARCHAR(100)    NULL,  -- 출고구분
    IsBOMReg                           NCHAR(1)         NULL,  -- BOM등록
    IsProcReg                          NCHAR(1)         NULL,  -- IsProcReg
    IsProcMat                          NCHAR(1)         NULL,  -- IsProcMat
    SMLimitTermKindName                NVARCHAR(100)    NULL,  -- 유통기한구분
    SMLimitTermKind                    INT              NULL,  -- 유통기간
    IsLotMng                           INT              NULL,  -- Lot관리
    IsSerialMng                        INT              NULL,  -- Serial관리
    SMAssetGrp                         INT              NULL,  -- SMAssetGrp
    PurCustName                        NVARCHAR(100)    NULL,  -- 구매거래처
    TrustCustName                      NVARCHAR(100)    NULL,  -- TrustCustName
    Remark                             NVARCHAR(100)    NULL,  -- Remark
    SMVatKindName                      NVARCHAR(100)    NULL,  -- 부가세구분
    PriceInVat                         INT              NULL,  -- 부가세구분
    IsFileCheck                        NCHAR(1)         NULL,  -- 첨부파일
    IsImangeCheck                      NCHAR(1)         NULL,  -- 이미지
    StdItemNo                          NVARCHAR(100)    NULL,  -- 대표품번
    STDItemSpec                        NVARCHAR(100)    NULL,  -- 대표규격
    MKCustName                         NVARCHAR(100)    NULL,  -- 메이커
    IsPrice                            NCHAR(1)         NULL,  -- 판매단가에부가세포함여부
    URL                                NVARCHAR(100)    NULL,  -- URL
    SMPurKind                          NVARCHAR(100)    NULL,  -- 납기구분내부코드
    PurKind                            NVARCHAR(100)    NULL,  -- 납기구분
    UMProperty                         INT              NULL,  -- UMProperty
    UMPropertyName                     NVARCHAR(100)    NULL,  -- UMPropertyName
    RowIDX                             INT              NULL,  -- RowIDX
    ColIDX                             INT              NULL,  -- ColIDX
    AddInfoName                        NVARCHAR(200)    NULL,  -- ITEM_CMF_11 - 치수 장변(mm) / ITEM_CMF_12 - 치수 단변(mm)
    RAW_JSON    NVARCHAR(MAX)  NULL
);
-- [품목] 62 데이터컬럼 + 공통3 + RAW_JSON

IF OBJECT_ID(N'DOI_VN_IF_PROCESS',N'U') IS NULL
CREATE TABLE DOI_VN_IF_PROCESS (
    SITE        NVARCHAR(4)    NOT NULL DEFAULT N'VN',
    LOAD_DTTM   DATETIME       NOT NULL DEFAULT GETDATE(),
    REQUEST_ID  NVARCHAR(50)   NULL,
    BizUnit                            INT              NULL,  -- 사업단위내부코드
    ProcSeq                            INT              NULL,  -- 공정내부코드
    ProcName                           NVARCHAR(100)    NULL,  -- 공정명
    Remark                             NVARCHAR(100)    NULL,  -- 비고
    IsProcQC                           INT              NULL,  -- 공정검사여부
    RAW_JSON    NVARCHAR(MAX)  NULL
);
-- [공정] 5 데이터컬럼 + 공통3 + RAW_JSON
