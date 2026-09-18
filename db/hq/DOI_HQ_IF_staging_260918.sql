/* =============================================================================
 * HQ 인터페이스 스테이징 추가분 (2026-09-18)
 *   ① DOI_HQ_IF_ETC_INOUT   : 기타입출고금액조회(통합) — VN DOI_VN_IF_ETC_INOUT 미러(SITE 기본 'HQ')
 *   ② DOI_HQ_IF_PRODUCT_SPEC: 면적기준(모델별 기본정보, MES product-spec) — top-level 배열 응답
 * 적재: UP_HQ_IF_LOAD_ETC_INOUT / UP_HQ_IF_LOAD_PRODUCT_SPEC
 * 변환: UP_HQ_IF_XFORM_ETC_INOUT(→DOI_ETC_INOUT) / UP_HQ_IF_XFORM_PRODUCT_SPEC(→DOI_MODEL_MAST 면적)
 * ============================================================================= */

-- ① 기타입출고금액 (ERP $.DataBlock1) — 22 데이터컬럼 전부 NVARCHAR(200) + 메타 + RAW_JSON
IF OBJECT_ID(N'DOI_HQ_IF_ETC_INOUT', N'U') IS NULL
CREATE TABLE DOI_HQ_IF_ETC_INOUT (
    SITE        NVARCHAR(4)    NOT NULL DEFAULT N'HQ',
    SEL_CODE    NVARCHAR(10)   NULL,
    LOAD_DTTM   DATETIME       NOT NULL DEFAULT GETDATE(),
    REQUEST_ID  NVARCHAR(50)   NULL,
    InOutDate            NVARCHAR(200) NULL,  -- 일자
    InOutName            NVARCHAR(200) NULL,  -- 입출고구분
    UMEtcOutKindSource   NVARCHAR(200) NULL,  -- 원천구분
    UMEtcOutKindDetail   NVARCHAR(200) NULL,  -- 기타입출고구분
    AssetName            NVARCHAR(200) NULL,  -- 품목자산분류
    UMItemClassLName     NVARCHAR(200) NULL,  -- 대분류
    UMItemClassMName     NVARCHAR(200) NULL,  -- 중분류
    UMItemClassSName     NVARCHAR(200) NULL,  -- 소분류
    ItemName             NVARCHAR(200) NULL,  -- 품명
    ItemNo               NVARCHAR(200) NULL,  -- 품번
    Spec                 NVARCHAR(200) NULL,  -- 규격
    UnitName             NVARCHAR(200) NULL,  -- 단위
    SMAdjustKindName     NVARCHAR(200) NULL,  -- 단수보정구분
    EtcOutQty            NVARCHAR(200) NULL,  -- 수량
    EtcOutAmt            NVARCHAR(200) NULL,  -- 금액
    EtcOutPrice          NVARCHAR(200) NULL,  -- 단가
    AccName              NVARCHAR(200) NULL,  -- 계정과목
    WHName               NVARCHAR(200) NULL,  -- 창고
    DeptName             NVARCHAR(200) NULL,  -- 사용부서
    Remark               NVARCHAR(200) NULL,  -- 특이사항
    ItemRemark           NVARCHAR(200) NULL,  -- 품목특이사항
    CustName             NVARCHAR(200) NULL,  -- 거래처
    RAW_JSON    NVARCHAR(MAX)  NULL
);
GO

-- ② 면적기준(모델별 기본정보, MES) — 응답 top-level 배열 [{area,Model,width,Spec,Prod_code,height}]. 마스터(SEL_CODE 없음)
IF OBJECT_ID(N'DOI_HQ_IF_PRODUCT_SPEC', N'U') IS NULL
CREATE TABLE DOI_HQ_IF_PRODUCT_SPEC (
    SITE        NVARCHAR(4)    NOT NULL DEFAULT N'HQ',
    LOAD_DTTM   DATETIME       NOT NULL DEFAULT GETDATE(),
    REQUEST_ID  NVARCHAR(50)   NULL,
    area        DECIMAL(19,5)  NULL,   -- 면적 (= width×height) → DOI_MODEL_MAST.XY
    Model       NVARCHAR(50)   NULL,   -- 모델(도우코드=품번)     → DOI_MODEL_MAST.MODEL
    width       DECIMAL(19,5)  NULL,   -- 가로(장변)              → DOI_MODEL_MAST.X
    Spec        NVARCHAR(200)  NULL,   -- 규격                    → DOI_MODEL_MAST.SPEC(76 절단)
    Prod_code   NVARCHAR(100)  NULL,   -- ERP 품목코드(A20823 등, 대응 컬럼 없음 — 참조용 보관)
    height      DECIMAL(19,5)  NULL,   -- 높이(단변)              → DOI_MODEL_MAST.Y
    RAW_JSON    NVARCHAR(MAX)  NULL
);
GO
