/**
 * 타시스템 > 수불 체크
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

    // ST001: 수량수식 검증
    @Override
    public List<Map<String, Object>> selectST001Detail(Map<String, Object> params) {
        return mapper.selectST001Detail(params);
    }

    @Override
    public List<Map<String, Object>> selectST001Summary(Map<String, Object> params) {
        return mapper.selectST001Summary(params);
    }

    // ST002: 생산재고연결 검증
    @Override
    public List<Map<String, Object>> selectST002Detail(Map<String, Object> params)
    {
        return mapper.selectST002Detail(params);
    }

    @Override
    public List<Map<String, Object>> selectST002Summary(Map<String, Object> params) {
        return mapper.selectST002Summary(params);
    }

    // ST003: 금액수식 검증
    @Override
    public List<Map<String, Object>> selectST003Detail(Map<String, Object> params) {
        return mapper.selectST003Detail(params);
    }

    @Override
    public List<Map<String, Object>> selectST003Summary(Map<String, Object> params) {
        return mapper.selectST003Summary(params);
    }

    @Override
    public List<Map<String, Object>> selectST004Detail(Map<String, Object> params) {
        return mapper.selectST004Detail(params);
    }

    @Override
    public List<Map<String, Object>> selectST004Summary(Map<String, Object> params) {
        return mapper.selectST004Summary(params);
    }

    @Override
    public List<Map<String, Object>> selectST005Detail(Map<String, Object> params) {
        return mapper.selectST005Detail(params);
    }

    @Override
    public List<Map<String, Object>> selectST005Summary(Map<String, Object> params) {
        return mapper.selectST005Summary(params);
    }
}