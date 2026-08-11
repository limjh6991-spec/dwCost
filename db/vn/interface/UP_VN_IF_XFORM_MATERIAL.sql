-- =============================================================================
-- 다운스트림 변환: DOI_VN_IF_MATERIAL (스테이징) -> doi_vn_material (운영)
--   자재코드 (마스터, IF SEL_CODE 무 -> site 기준)
--   멱등: 동일 키 삭제 후 재적재. API 원문 그대로 저장, 미매핑 컬럼은 NULL(보류).
-- =============================================================================
CREATE OR ALTER PROCEDURE UP_VN_IF_XFORM_MATERIAL
    @yyyymm  VARCHAR(6),
    @selCode VARCHAR(10) = N'ACTUAL',
    @site    VARCHAR(4) = N'VN'
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM doi_vn_material
    WHERE [yyyymm] = @yyyymm;

    INSERT INTO doi_vn_material
        ([자재명], [자재번호], [규격], [품목자산분류], [기준단위], [자재상태], [내외자구분], [중요도], [관리부서], [관리자], [자재대분류], [자재중분류], [자재소분류], [영문명], [출고구분], [대표자재], [BOM등록], [제품별공정소요자재], [Lot 관리], [Serial 관리], [단가등록여부], [유통기한구분], [유통기간], [등록자], [등록일], [품목설명], [기본구매처], [수탁거래처], [부가세구분], [판매단가에 부가세포함여부], [첨부파일], [이미지], [최종수정자], [최종수정일], [MAT_GRP_1], [MAT_GRP_2], [MAT_GRP_4], [MAT_GRP_5], [MAT_GRP_6], [MAT_GRP_7], [MAT_GRP_8], [MAT_GRP_9], [MAT_GRP_10], [MAT_CMF_1], [MAT_CMF_2], [MAT_CMF_3], [MAT_CMF_4], [MAT_CMF_5], [MAT_CMF_6], [MAT_CMF_7], [MAT_CMF_8], [MAT_CMF_9], [MAT_CMF_10], [MAT_CMF_11], [MAT_CMF_12], [MAT_CMF_13], [MAT_CMF_14], [MAT_CMF_15], [MAT_CMF_16], [MAT_CMF_17], [MAT_CMF_18], [MAT_CMF_19], [MAT_CMF_20], [FIRST_FLOW], [FIRST_FLOW_SEQ_NUM], [LAST_FLOW], [LAST_FLOW_SEQ_NUM], [MFG_DEVISION], [SUBCONTRACT_FLAG], [BASE_MAT_ID], [VENDOR_ID], [VENDOR_MAT_ID], [CUSTOMER_ID], [CUSTOMER_MAT_ID], [BOM_SET_ID], [APPLY_START_TIME], [APPLY_END_TIME], [APPROVAL_FLAG], [APPROVAL_USER_ID], [APPROVAL_TIME], [RELEASE_FLAG], [RELEASE_USER_ID], [RELEASE_TIME], [DEACTIVE_FLAG], [DEACTIVE_USER_ID], [DEACTIVE_TIME], [MAT_SHORT_DESC], [VENDOR], [IQC YN], [yyyymm], [edit_user], [edit_date])
    SELECT
        s.ItemName,  -- 자재명
        s.ItemNo,  -- 자재번호
        s.Spec,  -- 규격
        s.AssetName,  -- 품목자산분류
        s.UnitName,  -- 기준단위
        s.SMStatusName,  -- 자재상태
        s.SMInOutKindName,  -- 내외자구분
        s.SMABCName,  -- 중요도
        s.DeptName,  -- 관리부서
        s.EmpName,  -- 관리자
        s.ItemClassLName,  -- 자재대분류
        s.ItemClassMName,  -- 자재중분류
        s.ItemClassSName,  -- 자재소분류
        s.ItemEngName,  -- 영문명
        s.SMOutKindName,  -- 출고구분
        s.IsSTDItem,  -- 대표자재
        s.IsBOMReg,  -- BOM등록
        s.IsProcMat,  -- 제품별공정소요자재
        s.IsLotMng,  -- Lot 관리
        s.IsSerialMng,  -- Serial 관리
        s.IsPrice,  -- 단가등록여부
        s.SMLimitTermKindName,  -- 유통기한구분
        s.SMLimitTermKind,  -- 유통기간
        CAST(s.RegUserSeq AS nvarchar(50)),  -- 등록자
        s.RegDate,  -- 등록일
        s.Remark,  -- 품목설명
        s.PurCustName,  -- 기본구매처
        s.TrustCustName,  -- 수탁거래처
        s.SMVatKindName,  -- 부가세구분
        s.PriceInVat,  -- 판매단가에 부가세포함여부
        s.IsFileCheck,  -- 첨부파일
        s.IsImageCheck,  -- 이미지
        CAST(s.LastUserSeq AS nvarchar(50)),  -- 최종수정자
        s.LastDate,  -- 최종수정일
        s.MAT_GRP_1,  -- MAT_GRP_1
        s.MAT_GRP_2,  -- MAT_GRP_2
        s.MAT_GRP_4,  -- MAT_GRP_4
        s.MAT_GRP_5,  -- MAT_GRP_5
        s.MAT_GRP_6,  -- MAT_GRP_6
        s.MAT_GRP_7,  -- MAT_GRP_7
        s.MAT_GRP_8,  -- MAT_GRP_8
        s.MAT_GRP_9,  -- MAT_GRP_9
        s.MAT_GRP_10,  -- MAT_GRP_10
        s.MAT_CMF_1,  -- MAT_CMF_1
        s.MAT_CMF_2,  -- MAT_CMF_2
        s.MAT_CMF_3,  -- MAT_CMF_3
        s.MAT_CMF_4,  -- MAT_CMF_4
        s.MAT_CMF_5,  -- MAT_CMF_5
        s.MAT_CMF_6,  -- MAT_CMF_6
        s.MAT_CMF_7,  -- MAT_CMF_7
        s.MAT_CMF_8,  -- MAT_CMF_8
        s.MAT_CMF_9,  -- MAT_CMF_9
        s.MAT_CMF_10,  -- MAT_CMF_10
        s.MAT_CMF_11,  -- MAT_CMF_11
        s.MAT_CMF_12,  -- MAT_CMF_12
        s.MAT_CMF_13,  -- MAT_CMF_13
        s.MAT_CMF_14,  -- MAT_CMF_14
        s.MAT_CMF_15,  -- MAT_CMF_15
        s.MAT_CMF_16,  -- MAT_CMF_16
        s.MAT_CMF_17,  -- MAT_CMF_17
        s.MAT_CMF_18,  -- MAT_CMF_18
        s.MAT_CMF_19,  -- MAT_CMF_19
        s.MAT_CMF_20,  -- MAT_CMF_20
        s.FIRST_FLOW,  -- FIRST_FLOW
        CAST(s.FIRST_FLOW_SEQ_NUM AS nvarchar(20)),  -- FIRST_FLOW_SEQ_NUM
        s.LAST_FLOW,  -- LAST_FLOW
        CAST(s.LAST_FLOW_SEQ_NUM AS nvarchar(20)),  -- LAST_FLOW_SEQ_NUM
        s.MFG_DEVISION,  -- MFG_DEVISION
        s.SUBCONTRACT_FLAG,  -- SUBCONTRACT_FLAG
        s.BASE_MAT_ID,  -- BASE_MAT_ID
        s.VENDOR_ID,  -- VENDOR_ID
        s.VENDOR_MAT_ID,  -- VENDOR_MAT_ID
        s.CUSTOMER_ID,  -- CUSTOMER_ID
        s.CUSTOMER_MAT_ID,  -- CUSTOMER_MAT_ID
        s.BOM_SET_ID,  -- BOM_SET_ID
        s.APPLY_START_TIME,  -- APPLY_START_TIME
        s.APPLY_END_TIME,  -- APPLY_END_TIME
        s.APPROVAL_FLAG,  -- APPROVAL_FLAG
        s.APPROVAL_USER_ID,  -- APPROVAL_USER_ID
        s.APPROVAL_TIME,  -- APPROVAL_TIME
        s.RELEASE_FLAG,  -- RELEASE_FLAG
        s.RELEASE_USER_ID,  -- RELEASE_USER_ID
        s.RELEASE_TIME,  -- RELEASE_TIME
        s.DEACTIVE_FLAG,  -- DEACTIVE_FLAG
        s.DEACTIVE_USER_ID,  -- DEACTIVE_USER_ID
        s.DEACTIVE_TIME,  -- DEACTIVE_TIME
        s.MAT_SHORT_DESC,  -- MAT_SHORT_DESC
        s.VENDOR,  -- VENDOR
        s.IQC_YN,  -- IQC YN
        @yyyymm,  -- yyyymm
        N'IF',  -- edit_user
        GETDATE()   -- edit_date
    FROM DOI_VN_IF_MATERIAL s
    WHERE s.SITE = @site;

    SELECT @@ROWCOUNT AS transformed;
END;
