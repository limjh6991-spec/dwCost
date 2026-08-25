/**
 * VN 인터페이스 레지스트리 (18종).
 * 각 항목: 화면 key, 소스(ERP/MES), 엔드포인트 path(base-url 이후), 적재 프로시저, @selCode 사용여부.
 * 엔드포인트 URL/경로는 비밀정보가 아니므로 코드에 두되, 서버주소·인증정보는 application.yml(env)로 외부화한다.
 */
package com.dowinsys.cost.common.iface;

import java.util.Arrays;
import java.util.EnumMap;
import java.util.Map;
import java.util.Optional;

public enum IfEndpoint {

    // ===== 마스터(원가기준정보) - @selCode 미사용 =====
    ACCOUNT      (IfSource.ERP, "/Angkor.Ylw.Common.HttpExecute/RestOutsideService.svc/OpenApi/Wbs.Ylw.Account.BSSDAAccount/Query_Acc",                                    "UP_VN_IF_LOAD_ACCOUNT",       false, "UP_VN_IF_XFORM_ACCOUNT"),
    DEPT         (IfSource.ERP, "/Angkor.Ylw.Common.HttpExecute/RestOutsideService.svc/OpenApi/VEN.Ylw.XHR.BssDept/Query",                                                  "UP_VN_IF_LOAD_DEPT",          false, "UP_VN_IF_XFORM_DEPT"),
    ITEM         (IfSource.ERP, "/Angkor.Ylw.Common.HttpExecute/RestOutsideService.svc/OpenApi/WBS.Ylw.Sales.BSSDAItemInfo/Query",                                          "UP_VN_IF_LOAD_ITEM",          false),
    MATERIAL     (IfSource.ERP, "/Angkor.Ylw.Common.HttpExecute/RestOutsideService.svc/OpenApi/WBS.Ylw.Sales.BSSDAItemInfo/Query",                                          "UP_VN_IF_LOAD_MATERIAL",      false, "UP_VN_IF_XFORM_MATERIAL"),
    PROCESS      (IfSource.ERP, "/Angkor.Ylw.Common.HttpExecute/RestOutsideService.svc/OpenApi/WBS.Ylw.Production.BSSPDBaseProcess/Query",                                  "UP_VN_IF_LOAD_PROCESS",       false),

    // ===== 트랜잭션/조회 - @selCode 사용 =====
    ACCLANG      (IfSource.ERP, "//Angkor.Ylw.Common.HttpExecute/RestOutsideService.svc/OpenApi/Wbs.Ylw.AC.BSSACFSItemForName/Query",                                       "UP_VN_IF_LOAD_ACCLANG",       true),
    DEPT_COST    (IfSource.ERP, "/Angkor.Ylw.Common.HttpExecute/RestOutsideService.svc/OpenApi/Wbs.Ylw.Account.BSSACCCtrCostAmtExeList/Query_ACCCtrCostAmtExeList",         "UP_VN_IF_LOAD_DEPT_COST",     true, "UP_VN_IF_XFORM_DEPT_COST"),
    ITEM_INPUT   (IfSource.ERP, "/Angkor.Ylw.Common.HttpExecute/RestOutsideService.svc/OpenApi/WBS.Ylw.ESM.BSSESMCProdFMatInputAmt/Query",                                 "UP_VN_IF_LOAD_ITEM_INPUT",    true, "UP_VN_IF_XFORM_ITEM_INPUT"),
    EXP_CLAIM    (IfSource.ERP, "/Angkor.Ylw.Common.HttpExecute/RestOutsideService.svc/OpenApi/WBS.Ylw.Export.BSSSLExpSalesClaimItemList_DOWOO/Query",                     "UP_VN_IF_LOAD_EXP_CLAIM",     true, "UP_VN_IF_XFORM_EXP_CLAIM"),
    ITEM_PROC_MAT(IfSource.ERP, "/Angkor.Ylw.Common.HttpExecute/RestOutsideService.svc/OpenApi/WBS.Ylw.Production.BSSPDROUItemProcMatList/Query",                          "UP_VN_IF_LOAD_ITEM_PROC_MAT", true),
    ETC_INOUT    (IfSource.ERP, "/Angkor.Ylw.Common.HttpExecute/RestOutsideService.svc/OpenApi/WBS.Ylw.ESM.BSSESMCEtcOutAmt/Query",                                        "UP_VN_IF_LOAD_ETC_INOUT",     true, "UP_VN_IF_XFORM_ETC_INOUT"),
    STOCK_DETAIL (IfSource.ERP, "/Angkor.Ylw.Common.HttpExecute/RestOutsideService.svc/OpenApi/WBS.Ylw.ESM.BSSESMZStockMonthlyAmt/Query",                                  "UP_VN_IF_LOAD_STOCK_DETAIL",  true, "UP_VN_IF_XFORM_STOCK_DETAIL"),
    WH_STOCK_SUM (IfSource.ERP, "/Angkor.Ylw.Common.HttpExecute/RestOutsideService.svc/OpenApi/WBS.Ylw.Logistics.BSSLGWHStock/WHStockSumQuery",                            "UP_VN_IF_LOAD_WH_STOCK_SUM",  true),
    BIZ_STOCK_SUM(IfSource.ERP, "/Angkor.Ylw.Common.HttpExecute/RestOutsideService.svc/OpenApi/WBS.Ylw.Logistics.BSSLGWHStock/BizStockSumTotalQuery(Dynamic)",             "UP_VN_IF_LOAD_BIZ_STOCK_SUM", true),
    EXP_SALES    (IfSource.ERP, "/Angkor.Ylw.Common.HttpExecute/RestOutsideService.svc/OpenApi/WBS.Ylw.Sales.BSSSLSalesInfo/ExpSalesItemQuery",                            "UP_VN_IF_LOAD_EXP_SALES",     true, "UP_VN_IF_XFORM_EXP_SALES"),
    EXP_PERMIT   (IfSource.ERP, "/Angkor.Ylw.Common.HttpExecute/RestOutsideService.svc/OpenApi/WBS.Ylw.Export.BSSSLExpPermitList/ItemQuery",                               "UP_VN_IF_LOAD_EXP_PERMIT",    true),

    // ===== MES(미라콤) - @selCode 사용, data.rows =====
    WIP_SUBUL    (IfSource.MES, "/api/v1/wip_inv", "UP_VN_IF_LOAD_WIP_SUBUL", true, "UP_VN_IF_XFORM_WIP_SUBUL"),
    FG_SUBUL     (IfSource.MES, "/api/v1/fg_inv",  "UP_VN_IF_LOAD_FG_SUBUL",  true, "UP_VN_IF_XFORM_FG_SUBUL"),

    // ===== HQ(본사) - InterFace 정의서 ver1.0 HQ. site()='HQ'(_HQ 접미), ERP=hq-base-url =====
    //   계정코드=ACCOUNT(VN동일 500768), 부서별계정별비용=DEPT_COST(501057, 메서드명 List)
    ACCOUNT_HQ      (IfSource.ERP, "/Angkor.Ylw.Common.HttpExecute/RestOutsideService.svc/OpenApi/Wbs.Ylw.Account.BSSDAAccount/Query_Acc",                                     "UP_HQ_IF_LOAD_ACCOUNT",       false, "UP_HQ_IF_XFORM_ACCOUNT"),
    DEPT_COST_HQ    (IfSource.ERP, "/Angkor.Ylw.Common.HttpExecute/RestOutsideService.svc/OpenApi/Wbs.Ylw.Account.BSSACCCtrCostAmtExeList/Query_ACCCtrCostAmtExeList",          "UP_HQ_IF_LOAD_DEPT_COST",     true,  "UP_HQ_IF_XFORM_DEPT_COST"),
    STOCK_DETAIL_HQ (IfSource.ERP, "/Angkor.Ylw.Common.HttpExecute/RestOutsideService.svc/OpenApi/WBS.Ylw.ESM.BSSESMZStockMonthlyAmt/Query",                                   "UP_HQ_IF_LOAD_STOCK_DETAIL",  true,  "UP_HQ_IF_XFORM_STOCK_DETAIL"),  // 자재투입(재고금액상세)
    WH_STOCK_SUM_HQ (IfSource.ERP, "/Angkor.Ylw.Common.HttpExecute/RestOutsideService.svc/OpenApi/WBS.Ylw.Logistics.BSSLGWHStock/WHStockSumQuery",                             "UP_HQ_IF_LOAD_WH_STOCK_SUM",  true),                                  // 제품정보(창고별수불집계)
    DEPT_HQ         (IfSource.ERP, "/Angkor.Ylw.Common.HttpExecute/RestOutsideService.svc/OpenApi/WBS.Ylw.ESM.BSSDACCtr/Query",                                                "UP_HQ_IF_LOAD_DEPT",          false, "UP_HQ_IF_XFORM_DEPT"),                 // 부서코드(코스트센터)→doi_dept 업서트
    MATERIAL_HQ     (IfSource.ERP, "/Angkor.Ylw.Common.HttpExecute/RestOutsideService.svc/OpenApi/WBS.Ylw.Production.BSSPDROUItemProcMatList/Query",                           "UP_HQ_IF_LOAD_MATERIAL",      false),                                 // 자재코드(제품별공정별소요자재)
    SALES_HQ        (IfSource.ERP, "/Angkor.Ylw.Common.HttpExecute/RestOutsideService.svc/OpenApi/WBS.Ylw.Sales.BSSSLInvoiceInfo/ItemQuery",                                   "UP_HQ_IF_LOAD_SALES",         true,  "UP_HQ_IF_XFORM_SALES"),                // 매출정보-거래명세서(국내)→DOI_SALE_RESC[HQ]
    EXP_INVOICE_HQ  (IfSource.ERP, "/Angkor.Ylw.Common.HttpExecute/RestOutsideService.svc/OpenApi/WBS.Ylw.Sales.BSSSLInvoiceInfo/ExpInvoiceItemQuery",                         "UP_HQ_IF_LOAD_EXP_INVOICE",   true,  "UP_HQ_IF_XFORM_EXP_INVOICE");           // 매출정보-수출Invoice→DOI_INVOICE_RESC[HQ]

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
    /** 사업장 구분: 엔드포인트명이 _HQ 로 끝나면 본사(HQ), 아니면 비나(VN).
     *  (적재/변환 @site 인자·ERP base-url 선택에 사용 — VN 하드코딩 제거) */
    public String  site()       { return name().endsWith("_HQ") ? "HQ" : "VN"; }

    // ================================================================
    // 영림원 ERP OpenAPI 요청 seq 매핑 (InterFace 정의서 ver1.8 기준).
    //   배열 = {serviceSeq, pgmSeq, methodSeq, userSeq, languageSeq}
    //   - languageSeq=6 : 베트남어(VN). ※HQ 1, VN 6 .
    //   - userSeq : "권한 적용 사용자". 정의서 요청 JSON 샘플의 실동작값 사용.
    //       조회형(부서코드/부서별계정별비용/품목/투입/소요자재/기타입출고/재고상세/창고별수불/수출신고필증)=3,
    //       마스터일괄(계정/언어별계정/자재)·사업단위별수불=1.
    //       ※표 Discription은 전부 1로 찍혀 있으나 신뢰불가(languageSeq도 표=1이나 실제=6) → JSON샘플 우선.
    //       PROCESS/EXP_CLAIM/EXP_SALES 는 정의서 JSON샘플 부재 → 표값(userSeq=1) 유지, 테스트 시 확정.
    // ================================================================
    private static final Map<IfEndpoint, int[]> ERP_SEQ = new EnumMap<>(IfEndpoint.class);
    static {
        ERP_SEQ.put(ACCOUNT,       new int[]{500768,    500167,     1, 1, 6}); // 계정코드
        ERP_SEQ.put(ACCLANG,       new int[]{502221,    503002,     1, 1, 1}); // 언어별계정항목
        ERP_SEQ.put(DEPT,          new int[]{2720265,   2720412,    1, 3, 6}); // 부서코드
        ERP_SEQ.put(ITEM,          new int[]{501631,    500260,     1, 3, 6}); // 품목
        ERP_SEQ.put(MATERIAL,      new int[]{501631,    500261,     1, 1, 6}); // 자재코드
        ERP_SEQ.put(PROCESS,       new int[]{500172,    500173,     1, 1, 6}); // 공정(JSON샘플 없음)
        ERP_SEQ.put(DEPT_COST,     new int[]{501057,    500532,     1, 1, 6}); // 부서별계정별비용 (userSeq=1: Account 메서드 인가 계정)
        ERP_SEQ.put(ITEM_INPUT,    new int[]{501351,    500770,     1, 3, 6}); // 품목별투입조회
        ERP_SEQ.put(EXP_CLAIM,     new int[]{118021152, 118021828,  1, 1, 6}); // 수출Claim(JSON샘플 없음)
        ERP_SEQ.put(ITEM_PROC_MAT, new int[]{501138,    500315,     1, 3, 6}); // 제품별공정별소요자재
        ERP_SEQ.put(ETC_INOUT,     new int[]{520148,    520234,     1, 3, 6}); // 기타입출고금액조회
        ERP_SEQ.put(STOCK_DETAIL,  new int[]{501175,    500675,     1, 3, 6}); // 재고금액상세조회
        ERP_SEQ.put(WH_STOCK_SUM,  new int[]{501534,    501187,     2, 3, 6}); // 창고별수불집계조회
        ERP_SEQ.put(BIZ_STOCK_SUM, new int[]{501534,    521995,    17, 1, 1}); // 사업단위별수불집계
        ERP_SEQ.put(EXP_SALES,     new int[]{501278,    501047,     3, 1, 6}); // 매출정보-수출매출품목조회(JSON샘플 없음)
        ERP_SEQ.put(EXP_PERMIT,    new int[]{501306,    501043,     2, 3, 6}); // 매출정보-수출신고필증조회
        // ===== HQ(본사) — languageSeq=1(한국어), companySeq=1(동일), userSeq는 정의서 Root Param =====
        ERP_SEQ.put(ACCOUNT_HQ,      new int[]{500768,    500167,     1, 1, 1}); // 계정코드(VN과 동일 메서드/seq, 언어만 1)
        ERP_SEQ.put(DEPT_COST_HQ,    new int[]{501057,    500532,     1, 1, 1}); // 부서별계정별비용
        ERP_SEQ.put(STOCK_DETAIL_HQ, new int[]{501175,    500675,     1, 1, 1}); // 자재투입(재고금액상세)
        ERP_SEQ.put(WH_STOCK_SUM_HQ, new int[]{501534,    501187,     2, 1, 1}); // 제품정보(창고별수불집계, method2)
        ERP_SEQ.put(DEPT_HQ,         new int[]{500746,    500517,     1, 1, 1}); // 부서코드(코스트센터)
        ERP_SEQ.put(MATERIAL_HQ,     new int[]{501138,    500315,     1, 1, 1}); // 자재코드(소요자재)
        ERP_SEQ.put(SALES_HQ,        new int[]{501278,    501047,     3, 1, 1}); // 거래명세서(method3)
        ERP_SEQ.put(EXP_INVOICE_HQ,  new int[]{501229,    501032,     4, 1, 1}); // 수출Invoice(method4)
    }
    public Integer serviceSeq()  { int[] s = ERP_SEQ.get(this); return s == null ? null : s[0]; }
    public Integer pgmSeq()      { int[] s = ERP_SEQ.get(this); return s == null ? null : s[1]; }
    public Integer methodSeq()   { int[] s = ERP_SEQ.get(this); return s == null ? null : s[2]; }
    public Integer userSeq()     { int[] s = ERP_SEQ.get(this); return s == null ? null : s[3]; }
    public Integer languageSeq() { int[] s = ERP_SEQ.get(this); return s == null ? null : s[4]; }

    public boolean hasErpSeq()   { return ERP_SEQ.containsKey(this); }

    /** 화면에서 넘어온 key(대소문자 무시)로 조회 */
    public static Optional<IfEndpoint> of(String key) {
        if (key == null) return Optional.empty();
        String k = key.trim().toUpperCase();
        return Arrays.stream(values()).filter(e -> e.name().equals(k)).findFirst();
    }
}
