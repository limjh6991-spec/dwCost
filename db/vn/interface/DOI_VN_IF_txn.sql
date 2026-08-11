-- VN ERP/MES → CMS 인터페이스 트랜잭션/조회 테이블 12종 [DWCMSTEST/VN]
-- 방식B(CMS=O 또는 전체 + 공통 + RAW_JSON). 트랜잭션 공통: SITE·SEL_CODE·LOAD_DTTM·REQUEST_ID. MES는 data.rows만

IF OBJECT_ID(N'DOI_VN_IF_ACCLANG',N'U') IS NULL
CREATE TABLE DOI_VN_IF_ACCLANG (
    SITE        NVARCHAR(4)    NOT NULL DEFAULT N'VN',
    SEL_CODE    NVARCHAR(10)   NULL,
    LOAD_DTTM   DATETIME       NOT NULL DEFAULT GETDATE(),
    REQUEST_ID  NVARCHAR(50)   NULL,
    FSItemNo                             NVARCHAR(100)    NULL,  -- 계정대분류내부코드
    FSItemName                           NVARCHAR(100)    NULL,  -- 계정내부코드
    RowIDX                               INT              NULL,  -- 조회순서
    RAW_JSON    NVARCHAR(MAX)  NULL
);
-- [ERP] [언어별계정항목] 3 데이터컬럼

IF OBJECT_ID(N'DOI_VN_IF_DEPT_COST',N'U') IS NULL
CREATE TABLE DOI_VN_IF_DEPT_COST (
    SITE        NVARCHAR(4)    NOT NULL DEFAULT N'VN',
    SEL_CODE    NVARCHAR(10)   NULL,
    LOAD_DTTM   DATETIME       NOT NULL DEFAULT GETDATE(),
    REQUEST_ID  NVARCHAR(50)   NULL,
    CCtrName                             NVARCHAR(100)    NULL,  -- 코스트센터
    DeptSeq                              INT              NULL,  -- 부서내부코드
    AccNameCost                          NVARCHAR(100)    NULL,  -- 계정과목 + 비용구분
    AccNo                                NVARCHAR(100)    NULL,  -- 계정코드
    AccName                              NVARCHAR(100)    NULL,  -- 계정과목
    UMCostTypeName                       NVARCHAR(100)    NULL,  -- 비용구분
    AccSeq                               INT              NULL,  -- 계정과목내부코드
    DrAmt                                DECIMAL(19,5)    NULL,  -- 차변금액
    CrAmt                                DECIMAL(19,5)    NULL,  -- 대변금액
    RAW_JSON    NVARCHAR(MAX)  NULL
);
-- [ERP] [부서별계정별비용] 9 데이터컬럼

IF OBJECT_ID(N'DOI_VN_IF_ITEM_INPUT',N'U') IS NULL
CREATE TABLE DOI_VN_IF_ITEM_INPUT (
    SITE        NVARCHAR(4)    NOT NULL DEFAULT N'VN',
    SEL_CODE    NVARCHAR(10)   NULL,
    LOAD_DTTM   DATETIME       NOT NULL DEFAULT GETDATE(),
    REQUEST_ID  NVARCHAR(50)   NULL,
    ItemNo                               NVARCHAR(100)    NULL,  -- 제품번호
    ItemName                             NVARCHAR(100)    NULL,  -- 제품명
    ItemSpec                             NVARCHAR(100)    NULL,  -- 제품규격
    ProcName                             NVARCHAR(100)    NULL,  -- 공정명
    MatNo                                NVARCHAR(100)    NULL,  -- 자재번호
    MatName                              NVARCHAR(100)    NULL,  -- 자재명
    Spec                                 NVARCHAR(100)    NULL,  -- 자재규격
    InputQty                             DECIMAL(19,5)    NULL,  -- 투입수량
    WorkOrderSeq                         INT              NULL,  -- 작업지시번호
    WorkOrderNo                          NVARCHAR(100)    NULL,  -- 작업지시Seq
    Price                                DECIMAL(19,5)    NULL,  -- 단가
    Amt                                  DECIMAL(19,5)    NULL,  -- 투입금액
    InputAcc                             NVARCHAR(100)    NULL,  -- 생산투입비용계정
    InputCost                            NVARCHAR(100)    NULL,  -- 투입비용항목
    AssetName                            NVARCHAR(100)    NULL,  -- 제품품목자산분류
    MatAssetName                         NVARCHAR(100)    NULL,  -- 자재품목자산분류
    RAW_JSON    NVARCHAR(MAX)  NULL
);
-- [ERP] [품목별투입조회] 16 데이터컬럼

IF OBJECT_ID(N'DOI_VN_IF_EXP_CLAIM',N'U') IS NULL
CREATE TABLE DOI_VN_IF_EXP_CLAIM (
    SITE        NVARCHAR(4)    NOT NULL DEFAULT N'VN',
    SEL_CODE    NVARCHAR(10)   NULL,
    LOAD_DTTM   DATETIME       NOT NULL DEFAULT GETDATE(),
    REQUEST_ID  NVARCHAR(50)   NULL,
    BizUnitName                          NVARCHAR(100)    NULL,  -- 사업부문
    BizUnit                              INT              NULL,  -- 사업부문내부코드
    ClaimNo                              NVARCHAR(100)    NULL,  -- Claim번호
    ClaimSeq                             INT              NULL,  -- Claim내부번호
    ClaimSerl                            INT              NULL,  -- Claim내부순번
    ClaimDate                            NCHAR(8)         NULL,  -- ClaimDate
    SMExpKindName                        NVARCHAR(100)    NULL,  -- 반품종류
    UMOutKindName                        NVARCHAR(100)    NULL,  -- 반품구분
    SMConsignKind                        INT              NULL,  -- 위탁구분내부코드
    SMConsignKindName                    NVARCHAR(100)    NULL,  -- 위탁구분
    DeptName                             NVARCHAR(100)    NULL,  -- 부서
    EmpName                              NVARCHAR(100)    NULL,  -- 담당자
    CustName                             NVARCHAR(100)    NULL,  -- 거래처
    CustSeq                              INT              NULL,  -- 거래처내부코드
    CustNo                               NVARCHAR(100)    NULL,  -- 거래처번호
    CurrSeq                              INT              NULL,  -- 통화내부코드
    CurrName                             NVARCHAR(100)    NULL,  -- 통화
    ExRate                               DECIMAL(19,5)    NULL,  -- 환율
    ItemSeq                              INT              NULL,  -- 품목내부코드
    ItemName                             NVARCHAR(100)    NULL,  -- 품명
    ItemNo                               NVARCHAR(100)    NULL,  -- 품번
    Spec                                 NVARCHAR(100)    NULL,  -- 규격
    UnitSeq                              INT              NULL,  -- 단위내부코드
    UnitName                             NVARCHAR(100)    NULL,  -- 단위
    Qty                                  DECIMAL(19,5)    NULL,  -- 수량
    Price                                DECIMAL(19,5)    NULL,  -- 판매단가
    ItemPrice                            DECIMAL(19,5)    NULL,  -- 정가
    CustPrice                            DECIMAL(19,5)    NULL,  -- 판매기준가
    VATRate                              DECIMAL(19,5)    NULL,  -- 부가세율
    CurAmt                               DECIMAL(19,5)    NULL,  -- 판매금액
    CurVAT                               DECIMAL(19,5)    NULL,  -- 판매부가세
    DomAmt                               DECIMAL(19,5)    NULL,  -- 원화판매금액
    DomVAT                               DECIMAL(19,5)    NULL,  -- 원화부가세
    StdUnitSeq                           INT              NULL,  -- 기준단위내부코드
    StdUnitName                          NVARCHAR(100)    NULL,  -- 기준단위
    StdQty                               DECIMAL(19,5)    NULL,  -- 기준수량
    BKCustName                           NVARCHAR(100)    NULL,  -- Agent
    DVDateM                              NVARCHAR(100)    NULL,  -- 납기일
    Remark                               NVARCHAR(100)    NULL,  -- 비고
    BLDate                               NCHAR(8)         NULL,  -- BL일
    BLNo                                 NVARCHAR(100)    NULL,  -- BL번호
    BLRefNo                              NVARCHAR(100)    NULL,  -- BL원천관리번호
    PermitDate                           NCHAR(8)         NULL,
    PermitNo                             NVARCHAR(100)    NULL,
    PermitRefNo                          NVARCHAR(100)    NULL,
    SalesNo                              NVARCHAR(100)    NULL,
    SlipID                               NVARCHAR(100)    NULL,  -- 전표행번호
    SMProgressReturnTypeName             NVARCHAR(100)    NULL,  -- 반품진행
    SMProgressTypeName                   NVARCHAR(100)    NULL,  -- 재수출진행
    SMExpKind                            INT              NULL,  -- 반품종류내부코드
    SlipSeq                              INT              NULL,  -- 전표내부코드
    SourceNo                             NVARCHAR(100)    NULL,  -- 원천번호
    SourceRefNo                          NVARCHAR(100)    NULL,  -- 원천관리번호
    ISPJT                                NCHAR(1)         NULL,  -- PJT여부
    LotNo                                NVARCHAR(100)    NULL,  -- LotNo
    RemarkM                              NVARCHAR(100)    NULL,  -- Remarks
    Memo                                 NVARCHAR(100)    NULL,  -- 메모
    LastUserName                         NVARCHAR(100)    NULL,  -- 최종수정자
    LastDateTime                         NVARCHAR(200)    NULL,  -- 최종수정일
    WHName                               NVARCHAR(100)    NULL,  -- 창고명
    BLPrice                              DECIMAL(19,5)    NULL,  -- BL원천 월 품목 매출원가
    RAW_JSON    NVARCHAR(MAX)  NULL
);
-- [ERP] [수출Claim] 61 데이터컬럼

IF OBJECT_ID(N'DOI_VN_IF_ITEM_PROC_MAT',N'U') IS NULL
CREATE TABLE DOI_VN_IF_ITEM_PROC_MAT (
    SITE        NVARCHAR(4)    NOT NULL DEFAULT N'VN',
    SEL_CODE    NVARCHAR(10)   NULL,
    LOAD_DTTM   DATETIME       NOT NULL DEFAULT GETDATE(),
    REQUEST_ID  NVARCHAR(50)   NULL,
    ItemSeq                              INT              NULL,  -- 제품내부코드
    ItemName                             NVARCHAR(100)    NULL,  -- 제품명
    ItemNo                               NVARCHAR(100)    NULL,  -- 제품번호
    Spec                                 NVARCHAR(100)    NULL,  -- 제품규격
    UnitSeq                              INT              NULL,  -- 제품단위내부코드
    UnitName                             NVARCHAR(100)    NULL,  -- 제품단위
    ProcRev                              NVARCHAR(100)    NULL,  -- 공정차수
    ProcSeq                              INT              NULL,  -- 공정내부코드
    ProcName                             NVARCHAR(100)    NULL,  -- 공정
    AssyItemSeq                          INT              NULL,  -- 공정품목내부코드
    AssyItemName                         NVARCHAR(100)    NULL,  -- 공정품명
    AssyItemNo                           NVARCHAR(100)    NULL,  -- 공정품번
    AssySpec                             NVARCHAR(100)    NULL,  -- 공정품규격
    AssyUnitSeq                          INT              NULL,  -- 공정품단위내부코드
    AssyUnitName                         NVARCHAR(100)    NULL,  -- 공정품단위
    AssyQty                              NVARCHAR(200)    NULL,  -- 공정품소요량
    MatItemSeq                           INT              NULL,  -- 자재내부코드
    MatItemName                          NVARCHAR(100)    NULL,  -- 자재명
    MatItemNo                            NVARCHAR(100)    NULL,  -- 자재번호
    MatSpec                              NVARCHAR(100)    NULL,  -- 자재규격
    MatUnitSeq                           INT              NULL,  -- 자재단위내부코드
    MatUnitName                          NVARCHAR(100)    NULL,  -- 자재단위
    STDUnitSeq                           INT              NULL,  -- 기준단위내부코드
    STDUnitName                          NVARCHAR(100)    NULL,  -- 기준단위
    MatQtyNum                            NVARCHAR(200)    NULL,  -- 소요량분자
    MatQtyDen                            NVARCHAR(200)    NULL,  -- 소요량분모
    MatQty                               NVARCHAR(200)    NULL,  -- 소요량
    STDQty                               NVARCHAR(200)    NULL,  -- 기준단위수량
    InLossRate                           NVARCHAR(200)    NULL,  -- 내부Loss율
    InLossMatQty                         NVARCHAR(200)    NULL,  -- 내부Loss율반영 소요량
    OutLossRate                          NVARCHAR(200)    NULL,  -- 외부Loss율
    OutLossMatQty                        NVARCHAR(200)    NULL,  -- 외부Loss율반영 소요량
    LastDateTime                         NVARCHAR(200)    NULL,  -- 최종수정일시
    Remark                               NVARCHAR(100)    NULL,  -- 특이사항
    Memo1                                NVARCHAR(100)    NULL,  -- 메모1
    Memo2                                NVARCHAR(100)    NULL,  -- 메모2
    Memo3                                NVARCHAR(100)    NULL,  -- 메모3
    SMDelvType                           INT              NULL,  -- 조달구분내부코드
    SMDelvTypeName                       NVARCHAR(100)    NULL,  -- 조달구분
    BizUnit                              INT              NULL,  -- 사업단위내부코드
    BizUnitName                          NVARCHAR(100)    NULL,  -- 사업단위
    UptEmpSeq                            INT              NULL,  -- 최종수정자내부코드
    UptEmpName                           NVARCHAR(100)    NULL,  -- 최종수정자
    UptDate                              NCHAR(1)         NULL,  -- 최종수정일시
    Location                             NVARCHAR(100)    NULL,  -- Location
    MasterRemark                         NVARCHAR(100)    NULL,  -- 등록사유
    SubItemProcRev                       NVARCHAR(100)    NULL,  -- 반제품공정차수
    UserNo                               NVARCHAR(100)    NULL,  -- 표시순서
    ItemSerl                             NVARCHAR(200)    NULL,  -- 자재순번
    RegEmpName                           NVARCHAR(100)    NULL,  -- 최초작성자
    RegDate                              NCHAR(8)         NULL,  -- 최초작성일
    AssetName                            NVARCHAR(100)    NULL,  -- 품목자산분류
    UMItemClassLName                     NVARCHAR(100)    NULL,  -- 품목대분류명
    UMItemClassMName                     NVARCHAR(100)    NULL,  -- 품목중분류명
    UMItemClassName                      NVARCHAR(100)    NULL,  -- 품목소분류명
    MatAssetName                         NVARCHAR(100)    NULL,  -- 자재자산분류
    MatUMItemClassLName                  NVARCHAR(100)    NULL,  -- 자재대분류명
    MatUMItemClassMName                  NVARCHAR(100)    NULL,  -- 자재중분류명
    MatUMItemClassName                   NVARCHAR(100)    NULL,  -- 자재소분류명
    TimeUnitName                         NVARCHAR(100)    NULL,  -- 시간단위
    WorkHour                             NVARCHAR(100)    NULL,  -- 표준 작업시간
    RAW_JSON    NVARCHAR(MAX)  NULL
);
-- [ERP] [제품별공정별소요자재] 61 데이터컬럼

IF OBJECT_ID(N'DOI_VN_IF_WIP_SUBUL',N'U') IS NULL
CREATE TABLE DOI_VN_IF_WIP_SUBUL (
    SITE        NVARCHAR(4)    NOT NULL DEFAULT N'VN',
    SEL_CODE    NVARCHAR(10)   NULL,
    LOAD_DTTM   DATETIME       NOT NULL DEFAULT GETDATE(),
    REQUEST_ID  NVARCHAR(50)   NULL,
    factory                              VARCHAR(10)      NULL,  -- 공장코드 (Mã nhà máy)
    mat_id                               VARCHAR(50)      NULL,  -- 품목코드 (Mã hàng)
    mat_grp_1                            VARCHAR(50)      NULL,  -- 품목그룹1 (Nhóm hàng 1)
    work_date                            VARCHAR(8)       NULL,  -- 작업일자 YYYYMMDD (Ngày làm việc)
    boh_a_wip_before_pfl_50              INT              NULL,  -- A급 기초재고 WIP PFL전 (50)
    boh_a_wip_after_pfl_90               INT              NULL,  -- A급 기초재고 WIP PFL후 (90)
    boh_a_fgs_before_pfl_50              INT              NULL,  -- A급 기초재고 완제품 PFL전 (50)
    boh_a_fgs_after_pfl_90               INT              NULL,  -- A급 기초재고 완제품 PFL후 (90)
    boh_a_before_pfl_50                  INT              NULL,  -- A급 기초재고 합계 PFL전 (50)
    boh_a_after_pfl_90                   INT              NULL,  -- A급 기초재고 합계 PFL후 (90)
    boh_b_wip_before_pfl_50              INT              NULL,  -- B급 기초재고 WIP PFL전 (50)
    boh_b_wip_after_pfl_90               INT              NULL,  -- B급 기초재고 WIP PFL후 (90)
    boh_b_fgs_before_pfl_50              INT              NULL,  -- B급 기초재고 완제품 PFL전 (50)
    boh_b_fgs_after_pfl_90               INT              NULL,  -- B급 기초재고 완제품 PFL후 (90)
    boh_b_before_pfl_50                  INT              NULL,  -- B급 기초재고 합계 PFL전 (50)
    boh_b_after_pfl_90                   INT              NULL,  -- B급 기초재고 합계 PFL후 (90)
    t_boh_before_pfl_50                  INT              NULL,  -- 총 기초재고 PFL전 (50)
    t_boh_after_pfl_90                   INT              NULL,  -- 총 기초재고 PFL후 (90)
    input_usc_cutting_qty                INT              NULL,  -- USC 절단 투입량 (SL đầu vào cắt USC)
    change_code_qty                      INT              NULL,  -- 코드변경 수량 (SL đổi mã)
    input_re_sorting_qty                 INT              NULL,  -- 재선별 투입량 (SL đầu vào tái phân loại)
    input_rework_qty                     INT              NULL,  -- 재작업 투입량 (SL đầu vào tái chế)
    wip_etc_input                        INT              NULL,  -- 기타 투입 (Đầu vào khác)
    total_input_to_line                  INT              NULL,  -- 라인 투입 합계 (Tổng đầu vào line)
    total_input                          INT              NULL,  -- 총 투입 (Tổng đầu vào)
    normal_last_month                    INT              NULL,  -- 정상 전월분 (Bình thường - tháng trước)
    normal_this_month                    INT              NULL,  -- 정상 당월분 (Bình thường - tháng này)
    wh_rt_sorting                        INT              NULL,  -- 창고반품 - 선별 (Trả kho - phân loại)
    wh_rt_pfrw                           INT              NULL,  -- 창고반품 - PFRW (Trả kho - PFRW)
    wh_rt_plrw                           INT              NULL,  -- 창고반품 - PLRW (Trả kho - PLRW)
    backship_sorting                     INT              NULL,  -- 역출하 - 선별 (Xuất ngược - phân loại)
    backship_pfrw                        INT              NULL,  -- 역출하 - PFRW (Xuất ngược - PFRW)
    backship_plrw                        INT              NULL,  -- 역출하 - PLRW (Xuất ngược - PLRW)
    total_out_a_level                    INT              NULL,  -- A급 총 산출 (Tổng sản lượng cấp A)
    output_code_change_50                INT              NULL,  -- 산출 - 코드변경 (50)
    output_code_change_90                INT              NULL,  -- 산출 - 코드변경 (90)
    output_other_50                      INT              NULL,  -- 산출 - 기타 (50)
    output_other_90                      INT              NULL,  -- 산출 - 기타 (90)
    b_level_ship_paid_50                 INT              NULL,  -- B급 유상출하 (50)
    b_level_ship_paid_90                 INT              NULL,  -- B급 유상출하 (90)
    b_level_ship_paid                    INT              NULL,  -- B급 유상출하 합계
    b_level_ship_free_50                 INT              NULL,  -- B급 무상출하 (50)
    b_level_ship_free_90                 INT              NULL,  -- B급 무상출하 (90)
    b_level_ship_free                    INT              NULL,  -- B급 무상출하 합계
    b_level_ship_50                      INT              NULL,  -- B급 출하 합계 (50)
    b_level_ship_90                      INT              NULL,  -- B급 출하 합계 (90)
    total_out_b_level                    INT              NULL,  -- B급 총 산출 (Tổng sản lượng cấp B)
    total_output                         INT              NULL,  -- 총 산출 (Tổng sản lượng)
    scrap_before_pfl                     INT              NULL,  -- 폐기 PFL전 (Phế trước PFL)
    scrap_after_pfl                      INT              NULL,  -- 폐기 PFL후 (Phế sau PFL)
    scrap_total_qty                      INT              NULL,  -- 폐기 합계 (Tổng phế)
    eoh_line_wip_pfl_50                  INT              NULL,  -- 라인 기말재고 WIP PFL (50)
    eoh_line_wip_pfl_90                  INT              NULL,  -- 라인 기말재고 WIP PFL (90)
    eoh_line_fgs_pfl_50                  INT              NULL,  -- 라인 기말재고 완제품 PFL (50)
    eoh_line_fgs_pfl_90                  INT              NULL,  -- 라인 기말재고 완제품 PFL (90)
    eoh_b_wip_pfl_50                     INT              NULL,  -- B급 기말재고 WIP PFL (50)
    eoh_b_wip_pfl_90                     INT              NULL,  -- B급 기말재고 WIP PFL (90)
    eoh_b_fgs_pfl_50                     INT              NULL,  -- B급 기말재고 완제품 PFL (50)
    eoh_b_fgs_pfl_90                     INT              NULL,  -- B급 기말재고 완제품 PFL (90)
    t_eoh_wip_pfl_50                     INT              NULL,  -- 총 기말재고 WIP PFL (50)
    t_eoh_wip_pfl_90                     INT              NULL,  -- 총 기말재고 WIP PFL (90)
    t_eoh_b_pfl_50                       INT              NULL,  -- 총 B급 기말재고 PFL (50)
    t_eoh_b_pfl_90                       INT              NULL,  -- 총 B급 기말재고 PFL (90)
    t_eoh_mes_pfl_50                     INT              NULL,  -- MES 총 기말재고 PFL (50)
    t_eoh_mes_pfl_90                     INT              NULL,  -- MES 총 기말재고 PFL (90)
    RAW_JSON    NVARCHAR(MAX)  NULL
);
-- [MES] [생산수불] 65 데이터컬럼

IF OBJECT_ID(N'DOI_VN_IF_FG_SUBUL',N'U') IS NULL
CREATE TABLE DOI_VN_IF_FG_SUBUL (
    SITE        NVARCHAR(4)    NOT NULL DEFAULT N'VN',
    SEL_CODE    NVARCHAR(10)   NULL,
    LOAD_DTTM   DATETIME       NOT NULL DEFAULT GETDATE(),
    REQUEST_ID  NVARCHAR(50)   NULL,
    factory                              VARCHAR(10)      NULL,  -- 공장코드 (Mã nhà máy)
    work_date                            VARCHAR(8)       NULL,  -- 작업일자 YYYYMMDD (Ngày làm việc)
    mat_id                               VARCHAR(30)      NULL,  -- 품목코드 (Mã hàng)
    boh_ok_mes                           INT              NULL,  -- MES 기초재고 양품 (Tồn đầu kỳ OK)
    normal_last_month                    INT              NULL,  -- 정상 전월분 (Bình thường - tháng trước)
    normal_this_month                    INT              NULL,  -- 정상 당월분 (Bình thường - tháng này)
    backship_sorting                     INT              NULL,  -- 역출하 - 선별 (Xuất ngược - phân loại)
    backship_pfrw                        INT              NULL,  -- 역출하 - PFRW (Xuất ngược - PFRW)
    backship_plrw                        INT              NULL,  -- 역출하 - PLRW (Xuất ngược - PLRW)
    wh_rt_sorting                        INT              NULL,  -- 창고반품 - 선별 (Trả kho - phân loại)
    wh_rt_pfrw                           INT              NULL,  -- 창고반품 - PFRW (Trả kho - PFRW)
    wh_rt_plrw                           INT              NULL,  -- 창고반품 - PLRW (Trả kho - PLRW)
    etc_input                            INT              NULL,  -- 기타 입고 (Nhập khác)
    back_ship_ng_qty                     INT              NULL,  -- 불량 역출하 수량 (SL xuất ngược NG)
    total_wh_input                       INT              NULL,  -- 창고 입고 합계 (Tổng nhập kho)
    other_input_total                    INT              NULL,  -- 기타 입고 합계 (Tổng nhập khác)
    shipped_level_a_paid                 INT              NULL,  -- A급 유상출하 (Xuất bán cấp A)
    shipped_level_a_free                 INT              NULL,  -- A급 무상출하 (Xuất miễn phí cấp A)
    shipped_level_b_paid                 INT              NULL,  -- B급 유상출하 (Xuất bán cấp B)
    shipped_level_b_free                 INT              NULL,  -- B급 무상출하 (Xuất miễn phí cấp B)
    t_output_3                           INT              NULL,  -- 총 출하 (Tổng xuất hàng)
    line_transfer_total                  INT              NULL,  -- 라인 이동 합계 (Tổng chuyển line)
    etc_output                           INT              NULL,  -- 기타 출고 (Xuất khác)
    line_transfer_rework                 INT              NULL,  -- 라인 이동 - 재작업 (Chuyển line - tái chế)
    line_transfer_sorting                INT              NULL,  -- 라인 이동 - 선별 (Chuyển line - phân loại)
    other_output_total                   INT              NULL,  -- 기타 출고 합계 (Tổng xuất khác)
    total_out_qty                        INT              NULL,  -- 총 출고 수량 (Tổng SL xuất)
    eoh_ok_mes                           INT              NULL,  -- MES 기말재고 양품 (Tồn cuối kỳ OK)
    loss_spare                           INT              NULL,  -- 로스/예비 (Loss / dự phòng)
    RAW_JSON    NVARCHAR(MAX)  NULL
);
-- [MES] [재고수불] 29 데이터컬럼

IF OBJECT_ID(N'DOI_VN_IF_ETC_INOUT',N'U') IS NULL
CREATE TABLE DOI_VN_IF_ETC_INOUT (
    SITE        NVARCHAR(4)    NOT NULL DEFAULT N'VN',
    SEL_CODE    NVARCHAR(10)   NULL,
    LOAD_DTTM   DATETIME       NOT NULL DEFAULT GETDATE(),
    REQUEST_ID  NVARCHAR(50)   NULL,
    InOutDate                            NVARCHAR(200)    NULL,  -- 일자
    InOutName                            NVARCHAR(200)    NULL,  -- 입출고구분
    UMEtcOutKindSource                   NVARCHAR(200)    NULL,  -- 원천구분
    UMEtcOutKindDetail                   NVARCHAR(200)    NULL,  -- 기Type출고구분
    AssetName                            NVARCHAR(200)    NULL,  -- 품목자산분류
    UMItemClassLName                     NVARCHAR(200)    NULL,  -- 대분류
    UMItemClassMName                     NVARCHAR(200)    NULL,  -- 중분류
    UMItemClassSName                     NVARCHAR(200)    NULL,  -- 소분류
    ItemName                             NVARCHAR(200)    NULL,  -- 품명
    ItemNo                               NVARCHAR(200)    NULL,  -- 품번
    Spec                                 NVARCHAR(200)    NULL,  -- 규격
    UnitName                             NVARCHAR(200)    NULL,  -- 단위
    SMAdjustKindName                     NVARCHAR(200)    NULL,  -- 단수보정구분
    EtcOutQty                            NVARCHAR(200)    NULL,  -- 수량
    EtcOutAmt                            NVARCHAR(200)    NULL,  -- 금액
    EtcOutPrice                          NVARCHAR(200)    NULL,  -- 단가
    AccName                              NVARCHAR(200)    NULL,  -- 계정과목
    WHName                               NVARCHAR(200)    NULL,  -- 창고
    DeptName                             NVARCHAR(200)    NULL,  -- 사용부서
    Remark                               NVARCHAR(200)    NULL,  -- 특이사항
    ItemRemark                           NVARCHAR(200)    NULL,  -- 품목특이사항
    CustName                             NVARCHAR(200)    NULL,  -- 거래처
    RAW_JSON    NVARCHAR(MAX)  NULL
);
-- [ERP] [기타입출고금액조회] 22 데이터컬럼

IF OBJECT_ID(N'DOI_VN_IF_WH_STOCK_SUM',N'U') IS NULL
CREATE TABLE DOI_VN_IF_WH_STOCK_SUM (
    SITE        NVARCHAR(4)    NOT NULL DEFAULT N'VN',
    SEL_CODE    NVARCHAR(10)   NULL,
    LOAD_DTTM   DATETIME       NOT NULL DEFAULT GETDATE(),
    REQUEST_ID  NVARCHAR(50)   NULL,
    SMAssetGrpName                       NVARCHAR(200)    NULL,  -- 재고자산종류
    WHName                               NVARCHAR(200)    NULL,  -- 창고
    SMWHKindName                         NVARCHAR(200)    NULL,  -- 창고구분
    AssetName                            NVARCHAR(200)    NULL,  -- 품목자산분류
    ItemClassLName                       NVARCHAR(200)    NULL,  -- 품목대분류
    ItemClassMName                       NVARCHAR(200)    NULL,  -- 품목중분류
    ItemClassSName                       NVARCHAR(200)    NULL,  -- 품목소분류
    ItemName                             NVARCHAR(200)    NULL,  -- 품명
    ItemNo                               NVARCHAR(200)    NULL,  -- 품번
    Spec                                 NVARCHAR(200)    NULL,  -- 규격
    UnitName                             NVARCHAR(200)    NULL,  -- 단위
    SMStatusName                         NVARCHAR(200)    NULL,  -- 품목상태
    PrevQty                              NVARCHAR(200)    NULL,  -- 이월수량
    InQty                                NVARCHAR(200)    NULL,  -- 입고수량
    OutQty                               NVARCHAR(200)    NULL,  -- 출고수량
    StockQty                             NVARCHAR(200)    NULL,  -- 재고수량
    ItemSeq                              NVARCHAR(200)    NULL,  -- 품목내부코드
    UnitSeq                              NVARCHAR(200)    NULL,  -- 단위내부코드
    WHSeq                                NVARCHAR(200)    NULL,  -- 창고내부코드
    SMWHKind                             NVARCHAR(200)    NULL,  -- 창고구분내부코드
    Location                             NVARCHAR(200)    NULL,  -- Location
    SafetyQty                            NVARCHAR(200)    NULL,  -- 안전재고수량
    CostWHName                           NVARCHAR(200)    NULL,  -- 창고그룹
    IsLot                                NVARCHAR(200)    NULL,  -- Lot관리여부
    RAW_JSON    NVARCHAR(MAX)  NULL
);
-- [ERP] [창고별수불집계조회] 24 데이터컬럼

IF OBJECT_ID(N'DOI_VN_IF_BIZ_STOCK_SUM',N'U') IS NULL
CREATE TABLE DOI_VN_IF_BIZ_STOCK_SUM (
    SITE        NVARCHAR(4)    NOT NULL DEFAULT N'VN',
    SEL_CODE    NVARCHAR(10)   NULL,
    LOAD_DTTM   DATETIME       NOT NULL DEFAULT GETDATE(),
    REQUEST_ID  NVARCHAR(50)   NULL,
    Title                                NVARCHAR(100)    NULL,  -- 커스텀 필드 1-1
    TitleSeq                             INT              NULL,  -- 커스텀 필드 1-2
    Title2                               NVARCHAR(100)    NULL,  -- 커스텀 필드 2-1
    TitleSeq2                            INT              NULL,  -- 커스텀 필드 2-2
    BizUnit                              INT              NULL,  -- 사업부문내부코드
    BizUnitName                          NVARCHAR(100)    NULL,  -- 사업부문
    AssetName                            NVARCHAR(100)    NULL,  -- 품목자산분류
    SMAssetGrpName                       NVARCHAR(100)    NULL,  -- 재고자산종류
    ItemClassLName                       NVARCHAR(100)    NULL,  -- 품목대분류
    ItemClassMName                       NVARCHAR(100)    NULL,  -- 품목중분류
    ItemClassSName                       NVARCHAR(100)    NULL,  -- 품목소분류
    ItemName                             NVARCHAR(100)    NULL,  -- 품명
    ItemNo                               NVARCHAR(100)    NULL,  -- 품번
    Spec                                 NVARCHAR(100)    NULL,  -- 규격
    UnitName                             NVARCHAR(100)    NULL,  -- 단위
    SMStatusName                         NVARCHAR(100)    NULL,  -- 품목상태
    ItemSeq                              INT              NULL,  -- 품목내부코드
    UnitSeq                              INT              NULL,  -- 단위내부코드
    PrevQty                              DECIMAL(19,5)    NULL,  -- 이월수량
    InQty                                DECIMAL(19,5)    NULL,  -- 입고수량
    OutQty                               DECIMAL(19,5)    NULL,  -- 출고수량
    StockQty                             DECIMAL(19,5)    NULL,  -- 재고수량
    RowIDX                               INT              NULL,  -- 커스텀 필드 RowIDX
    ColIDX                               INT              NULL,  -- 커스텀 필드 ColIDX
    Qty                                  DECIMAL(19,5)    NULL,  -- 커스텀 필드 Value
    RAW_JSON    NVARCHAR(MAX)  NULL
);
-- [ERP] [사업단위별수불집계] 25 데이터컬럼

IF OBJECT_ID(N'DOI_VN_IF_EXP_SALES',N'U') IS NULL
CREATE TABLE DOI_VN_IF_EXP_SALES (
    SITE        NVARCHAR(4)    NOT NULL DEFAULT N'VN',
    SEL_CODE    NVARCHAR(10)   NULL,
    LOAD_DTTM   DATETIME       NOT NULL DEFAULT GETDATE(),
    REQUEST_ID  NVARCHAR(50)   NULL,
    BizUnit                              INT              NULL,  -- 사업부문내부코드
    BizUnitName                          NVARCHAR(100)    NULL,  -- 사업부문
    SMExpKind                            INT              NULL,  -- 수출구분내부코드
    SMExpKindName                        NVARCHAR(100)    NULL,  -- 수출구분
    DeptSeq                              INT              NULL,  -- 부서내부코드
    DeptName                             NVARCHAR(100)    NULL,  -- 부서명
    EmpSeq                               INT              NULL,  -- 담당자내부코드
    EmpName                              NVARCHAR(100)    NULL,  -- 담당자
    CustSeq                              INT              NULL,  -- Buyer내부코드
    CustName                             NVARCHAR(100)    NULL,  -- Buyer
    ItemSeq                              INT              NULL,  -- 품목내부코드
    ItemName                             NVARCHAR(100)    NULL,  -- 품명
    ItemNo                               NVARCHAR(100)    NULL,  -- 품번
    Spec                                 NVARCHAR(100)    NULL,  -- 규격
    UnitSeq                              INT              NULL,  -- 단위내부코드
    UnitName                             NVARCHAR(100)    NULL,  -- 단위
    ItemPrice                            DECIMAL(19,5)    NULL,  -- 품목단가
    CustPrice                            DECIMAL(19,5)    NULL,  -- 거래처단가
    Qty                                  DECIMAL(19,5)    NULL,  -- 수량
    Price                                DECIMAL(19,5)    NULL,  -- 판매단가
    CurAmt                               DECIMAL(19,5)    NULL,  -- 판매금액
    DomAmt                               DECIMAL(19,5)    NULL,  -- 원화판매금액
    WHSeq                                INT              NULL,  -- 창고내부코드
    WHName                               NVARCHAR(100)    NULL,  -- 창고
    RemarkM                              NVARCHAR(100)    NULL,  -- 특이사항
    AccSeq                               INT              NULL,  -- 정산계정코드
    AccName                              NVARCHAR(100)    NULL,  -- 정산계정
    UMPriceTerms                         NVARCHAR(100)    NULL,  -- 가격조건내부코드
    UMPriceTermsName                     NVARCHAR(100)    NULL,  -- 가격조건
    CurrName                             NVARCHAR(100)    NULL,  -- 통화
    ExRate                               DECIMAL(19,5)    NULL,  -- 환율
    RemarkI                              NVARCHAR(100)    NULL,  -- 품목특이사항
    InvoiceRefNo                         NVARCHAR(100)    NULL,  -- Invoice No
    UMChannelName                        NVARCHAR(100)    NULL,  -- 유통구조
    InvoiceDate                          NCHAR(8)         NULL,  -- 거래명세서일자
    RAW_JSON    NVARCHAR(MAX)  NULL
);
-- [ERP] [매출정보-수출매출품목조회] 35 데이터컬럼

IF OBJECT_ID(N'DOI_VN_IF_EXP_PERMIT',N'U') IS NULL
CREATE TABLE DOI_VN_IF_EXP_PERMIT (
    SITE        NVARCHAR(4)    NOT NULL DEFAULT N'VN',
    SEL_CODE    NVARCHAR(10)   NULL,
    LOAD_DTTM   DATETIME       NOT NULL DEFAULT GETDATE(),
    REQUEST_ID  NVARCHAR(50)   NULL,
    BizUnit                              NVARCHAR(200)    NULL,  -- 사업부문내부코드
    BizUnitName                          NVARCHAR(200)    NULL,  -- 사업부문
    PermitDate                           NVARCHAR(200)    NULL,  -- 수입통관일
    PermitNo                             NVARCHAR(200)    NULL,  -- 수입통관관리번호
    PermitRefNo                          NVARCHAR(200)    NULL,  -- 수입통관번호
    SMExpKind                            NVARCHAR(200)    NULL,  -- 수출구분내부코드
    SMExpKindName                        NVARCHAR(200)    NULL,  -- 수출구분
    CustSeq                              NVARCHAR(200)    NULL,  -- 거래처내부코드
    CustName                             NVARCHAR(200)    NULL,  -- 거래처
    CustNo                               NVARCHAR(200)    NULL,  -- 거래처번호
    CurrSeq                              NVARCHAR(200)    NULL,  -- 통화내부코드
    CurrName                             NVARCHAR(200)    NULL,  -- 통화
    UMPriceTerms                         NVARCHAR(200)    NULL,  -- 가격조건내부코드
    UMPriceTermsName                     NVARCHAR(200)    NULL,  -- 가격조건
    DeptSeq                              NVARCHAR(200)    NULL,  -- 부서내부코드
    DeptName                             NVARCHAR(200)    NULL,  -- 부서
    PermitType                           NVARCHAR(200)    NULL,  -- 수출결재방법내부코드
    PermitTypeName                       NVARCHAR(200)    NULL,  -- 수출결재방법
    EmpSeq                               NVARCHAR(200)    NULL,  -- 담당자내부코드
    ExRate                               NVARCHAR(200)    NULL,  -- 환율
    EmpName                              NVARCHAR(200)    NULL,  -- 담당자
    ItemSeq                              NVARCHAR(200)    NULL,  -- 품목내부코드
    ItemName                             NVARCHAR(200)    NULL,  -- 품명
    ItemNo                               NVARCHAR(200)    NULL,  -- 품번
    Spec                                 NVARCHAR(200)    NULL,  -- 규격
    UnitSeq                              NVARCHAR(200)    NULL,  -- 단위내부코드
    UnitName                             NVARCHAR(200)    NULL,  -- 단위
    Qty                                  NVARCHAR(200)    NULL,  -- 수량
    FOBPrice                             NVARCHAR(200)    NULL,  -- 판매단가
    DomPrice                             NVARCHAR(200)    NULL,  -- 원화금액
    CurAmt                               NVARCHAR(200)    NULL,  -- 금액
    DomAmt                               NVARCHAR(200)    NULL,  -- 원화금액
    FOBDomAmt                            NVARCHAR(200)    NULL,  -- 원화판매단가
    Remark                               NVARCHAR(200)    NULL,  -- 특이사항
    RemarkI                              NVARCHAR(200)    NULL,  -- 품목특이사항
    UMEtcOutkind                         NVARCHAR(200)    NULL,  -- 기타출고구분내부코드
    UMEtcOutkindName                     NVARCHAR(200)    NULL,  -- 기타출고구분
    SMProgressTypeName                   NVARCHAR(200)    NULL,  -- 진행상태내부코드
    SalesAmt                             NVARCHAR(200)    NULL,  -- 판매금액
    InvoiceRefNo                         NVARCHAR(200)    NULL,  -- InvoiceNo
    SourceNo                             NVARCHAR(200)    NULL,  -- 원천번호
    SourceRefNo                          NVARCHAR(200)    NULL,  -- 원천관리번호
    SMSalesProgTypeName                  NVARCHAR(200)    NULL,  -- 진행상태
    RAW_JSON    NVARCHAR(MAX)  NULL
);
-- [ERP] [매출정보-수출신고필증조회] 43 데이터컬럼
