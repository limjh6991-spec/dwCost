/**
 * 타시스템 > 생산/입고/판매 수불 체크 통합
 */
package com.dowinsys.cost.web.c0007000.service.impl;

import com.dowinsys.cost.web.c0007000.mapper.C0007006Mapper;
import com.dowinsys.cost.web.c0007000.service.C0007006Service;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;

@Service("com.dowinsys.cost.web.c0007000.service.C0007006")
public class C0007006ServiceImpl implements C0007006Service {

    @Autowired
    C0007006Mapper mapper;

    @Override
    public List<Map<String, Object>> selectSummary(Map<String, Object> params) {
        return mapper.selectSummary(params);
    }

    @Override
    public List<Map<String, Object>> selectSummary2(Map<String, Object> params) {
        return mapper.selectSummary2(params);
    }

    @Override
    public List<Map<String, Object>> selectBalanceCheck(Map<String, Object> params) {
        return mapper.selectBalanceCheck(params);
    }

    @Override
    public List<Map<String, Object>> selectContinuityCheck(Map<String, Object> params) {
        return mapper.selectContinuityCheck(params);
    }

    @Override
    public List<Map<String, Object>> selectIncomeBalanceCheck(Map<String, Object> params) {
        return mapper.selectIncomeBalanceCheck(params);
    }

    @Override
    public List<Map<String, Object>> selectIncomeContinuityCheck(Map<String, Object> params) {
        return mapper.selectIncomeContinuityCheck(params);
    }

    @Override
    public List<Map<String, Object>> selectIncomeSummary(Map<String, Object> params) {
        return mapper.selectIncomeSummary(params);
    }

    @Override
    public List<Map<String, Object>> selectIncomeSummary2(Map<String, Object> params) {
        return mapper.selectIncomeSummary2(params);
    }

    @Override
    public List<Map<String, Object>> selectProdToStock(Map<String, Object> params) {
        return mapper.selectProdToStock(params);
    }

    @Override
    public List<Map<String, Object>> selectStockToSale(Map<String, Object> params) {
        return mapper.selectStockToSale(params);
    }

    @Override
    public List<Map<String, Object>> selectSummary1(Map<String, Object> params) {
        return mapper.selectSummary1(params);
    }

    @Override
    public List<Map<String, Object>> selectSaleSummary2(Map<String, Object> params) {
        return mapper.selectSaleSummary2(params);
    }
}
