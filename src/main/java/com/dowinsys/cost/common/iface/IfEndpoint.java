/**
 * VN 인터페이스 레지스트리 (18종).
 * 각 항목: 화면 key, 소스(ERP/MES), 엔드포인트 path(base-url 이후), 적재 프로시저, @selCode 사용여부.
 * 엔드포인트 URL/경로는 비밀정보가 아니므로 코드에 두되, 서버주소·인증정보는 application.yml(env)로 외부화한다.
 */
package com.dowinsys.cost.common.iface;

import java.util.Arrays;
import java.util.Optional;

public enum IfEndpoint {

    // ===== 마스터(원가기준정보) - @selCode 미사용 =====
    ACCOUNT      (IfSource.ERP, "/Angkor.Ylw.Common.HttpExecute/RestOutsideService.svc/OpenApi/Wbs.Ylw.Account.BSSDAAccount/Query_Acc",                                    "UP_VN_IF_LOAD_ACCOUNT",       false),
    DEPT         (IfSource.ERP, "/Angkor.Ylw.Common.HttpExecute/RestOutsideService.svc/OpenApi/VEN.Ylw.XHR.BssDept/Query",                                                  "UP_VN_IF_LOAD_DEPT",          false),
    ITEM         (IfSource.ERP, "/Angkor.Ylw.Common.HttpExecute/RestOutsideService.svc/OpenApi/WBS.Ylw.Sales.BSSDAItemInfo/Query",                                          "UP_VN_IF_LOAD_ITEM",          false),
    MATERIAL     (IfSource.ERP, "/Angkor.Ylw.Common.HttpExecute/RestOutsideService.svc/OpenApi/WBS.Ylw.Sales.BSSDAItemInfo/Query",                                          "UP_VN_IF_LOAD_MATERIAL",      false),
    PROCESS      (IfSource.ERP, "/Angkor.Ylw.Common.HttpExecute/RestOutsideService.svc/OpenApi/WBS.Ylw.Production.BSSPDBaseProcess/Query",                                  "UP_VN_IF_LOAD_PROCESS",       false),

    // ===== 트랜잭션/조회 - @selCode 사용 =====
    ACCLANG      (IfSource.ERP, "//Angkor.Ylw.Common.HttpExecute/RestOutsideService.svc/OpenApi/Wbs.Ylw.AC.BSSACFSItemForName/Query",                                       "UP_VN_IF_LOAD_ACCLANG",       true),
    DEPT_COST    (IfSource.ERP, "/Angkor.Ylw.Common.HttpExecute/RestOutsideService.svc/OpenApi/Wbs.Ylw.Account.BSSACCCtrCostAmtExeList/Query_ACCCtrCostAmtExeL",            "UP_VN_IF_LOAD_DEPT_COST",     true, "UP_VN_IF_XFORM_DEPT_COST"),
    ITEM_INPUT   (IfSource.ERP, "/Angkor.Ylw.Common.HttpExecute/RestOutsideService.svc/OpenApi/WBS.Ylw.ESM.BSSESMCProdFMatInputAmt/Query",                                 "UP_VN_IF_LOAD_ITEM_INPUT",    true),
    EXP_CLAIM    (IfSource.ERP, "/Angkor.Ylw.Common.HttpExecute/RestOutsideService.svc/OpenApi/WBS.Ylw.Export.BSSSLExpSalesClaimItemList_DOWOO/Query",                     "UP_VN_IF_LOAD_EXP_CLAIM",     true),
    ITEM_PROC_MAT(IfSource.ERP, "/Angkor.Ylw.Common.HttpExecute/RestOutsideService.svc/OpenApi/WBS.Ylw.Production.BSSPDROUItemProcMatList/Query",                          "UP_VN_IF_LOAD_ITEM_PROC_MAT", true),
    ETC_INOUT    (IfSource.ERP, "/Angkor.Ylw.Common.HttpExecute/RestOutsideService.svc/OpenApi/WBS.Ylw.ESM.BSSESMCEtcOutAmt/Query",                                        "UP_VN_IF_LOAD_ETC_INOUT",     true, "UP_VN_IF_XFORM_ETC_INOUT"),
    STOCK_DETAIL (IfSource.ERP, "/Angkor.Ylw.Common.HttpExecute/RestOutsideService.svc/OpenApi/WBS.Ylw.ESM.BSSESMZStockMonthlyAmt/Query",                                  "UP_VN_IF_LOAD_STOCK_DETAIL",  true, "UP_VN_IF_XFORM_STOCK_DETAIL"),
    WH_STOCK_SUM (IfSource.ERP, "/Angkor.Ylw.Common.HttpExecute/RestOutsideService.svc/OpenApi/WBS.Ylw.Logistics.BSSLGWHStock/WHStockSumQuery",                            "UP_VN_IF_LOAD_WH_STOCK_SUM",  true),
    BIZ_STOCK_SUM(IfSource.ERP, "/Angkor.Ylw.Common.HttpExecute/RestOutsideService.svc/OpenApi/WBS.Ylw.Logistics.BSSLGWHStock/BizStockSumTotalQuery(Dynamic)",             "UP_VN_IF_LOAD_BIZ_STOCK_SUM", true),
    EXP_SALES    (IfSource.ERP, "/Angkor.Ylw.Common.HttpExecute/RestOutsideService.svc/OpenApi/WBS.Ylw.Sales.BSSSLSalesInfo/ExpSalesItemQuery",                            "UP_VN_IF_LOAD_EXP_SALES",     true, "UP_VN_IF_XFORM_EXP_SALES"),
    EXP_PERMIT   (IfSource.ERP, "/Angkor.Ylw.Common.HttpExecute/RestOutsideService.svc/OpenApi/WBS.Ylw.Export.BSSSLExpPermitList/ItemQuery",                               "UP_VN_IF_LOAD_EXP_PERMIT",    true),

    // ===== MES(미라콤) - @selCode 사용, data.rows =====
    WIP_SUBUL    (IfSource.MES, "/api/v1/wip_inv", "UP_VN_IF_LOAD_WIP_SUBUL", true),
    FG_SUBUL     (IfSource.MES, "/api/v1/fg_inv",  "UP_VN_IF_LOAD_FG_SUBUL",  true, "UP_VN_IF_XFORM_FG_SUBUL");

    private final IfSource source;
    private final String path;
    private final String loadProc;
    private final boolean useSelCode;
    private final String xformProc;   // 적재 후 운영반영 변환 프로시저 (없으면 null)

    IfEndpoint(IfSource source, String path, String loadProc, boolean useSelCode) {
        this(source, path, loadProc, useSelCode, null);
    }

    IfEndpoint(IfSource source, String path, String loadProc, boolean useSelCode, String xformProc) {
        this.source = source;
        this.path = path;
        this.loadProc = loadProc;
        this.useSelCode = useSelCode;
        this.xformProc = xformProc;
    }

    public IfSource source()    { return source; }
    public String  path()       { return path; }
    public String  loadProc()   { return loadProc; }
    public boolean useSelCode() { return useSelCode; }
    public String  xformProc()  { return xformProc; }

    /** 화면에서 넘어온 key(대소문자 무시)로 조회 */
    public static Optional<IfEndpoint> of(String key) {
        if (key == null) return Optional.empty();
        String k = key.trim().toUpperCase();
        return Arrays.stream(values()).filter(e -> e.name().equals(k)).findFirst();
    }
}
