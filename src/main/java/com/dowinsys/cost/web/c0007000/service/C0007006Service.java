/**
 * 타시스템 > 생산/입고/판매 수불 체크 통합
 */
package com.dowinsys.cost.web.c0007000.service;

import java.util.List;
import java.util.Map;

public interface C0007006Service {
    // 생산수불 자체 체크
    List<Map<String, Object>> selectSummary(Map<String, Object> params);
    List<Map<String, Object>> selectSummary2(Map<String, Object> params);
    List<Map<String, Object>> selectBalanceCheck(Map<String, Object> params);
    List<Map<String, Object>> selectContinuityCheck(Map<String, Object> params);
    
    // 입고수불 자체 체크
    List<Map<String, Object>> selectIncomeBalanceCheck(Map<String, Object> params);
    List<Map<String, Object>> selectIncomeContinuityCheck(Map<String, Object> params);
    List<Map<String, Object>> selectIncomeSummary(Map<String, Object> params);
    List<Map<String, Object>> selectIncomeSummary2(Map<String, Object> params);
    
    // 생산/입고/판매 체크
    List<Map<String, Object>> selectProdToStock(Map<String, Object> params);
    List<Map<String, Object>> selectStockToSale(Map<String, Object> params);
    List<Map<String, Object>> selectSummary1(Map<String, Object> params);
    List<Map<String, Object>> selectSaleSummary2(Map<String, Object> params);

    // 제품수불 체크
    List<Map<String, Object>> selectST001Detail(Map<String, Object> params);
    List<Map<String, Object>> selectST001Summary(Map<String, Object> params);
    List<Map<String, Object>> selectST002Detail(Map<String, Object> params);
    List<Map<String, Object>> selectST002Summary(Map<String, Object> params);
    List<Map<String, Object>> selectST003Detail(Map<String, Object> params);
    List<Map<String, Object>> selectST003Summary(Map<String, Object> params);
    List<Map<String, Object>> selectST004Detail(Map<String, Object> params);
    List<Map<String, Object>> selectST004Summary(Map<String, Object> params);
    List<Map<String, Object>> selectST005Detail(Map<String, Object> params);
    List<Map<String, Object>> selectST005Summary(Map<String, Object> params);
}