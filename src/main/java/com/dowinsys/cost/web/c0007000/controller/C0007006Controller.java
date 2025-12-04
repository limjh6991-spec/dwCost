/**
 * 타시스템 > 수불 체크
 */
package com.dowinsys.cost.web.c0007000.controller;

import com.dowinsys.cost.web.c0007000.service.C0007006Service;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

@RestController("com.dowinsys.cost.web.c0007000.controller.C0007006Controller")
@RequestMapping("/api/c0007000/c0007006")
public class C0007006Controller {

    @Autowired
    C0007006Service service;

    /**
     * 생산수불 자체 체크 - 요약 정보 조회
     */
    @PostMapping("/selectSummary")
    public ResponseEntity<List<Map<String, Object>>> selectSummary(@RequestBody Map<String, Object> params) {
        List<Map<String, Object>> result = service.selectSummary(params);
        return ResponseEntity.ok(result);
    }

    /**
     * 생산수불 자체 체크 - 요약 정보 2 조회
     */
    @PostMapping("/selectSummary2")
    public ResponseEntity<List<Map<String, Object>>> selectSummary2(@RequestBody Map<String, Object> params) {
        List<Map<String, Object>> result = service.selectSummary2(params);
        return ResponseEntity.ok(result);
    }

    /**
     * 생산수불 자체 체크 - 밸런스 체크 데이터 조회
     */
    @PostMapping("/selectBalanceCheck")
    public ResponseEntity<List<Map<String, Object>>> selectBalanceCheck(@RequestBody Map<String, Object> params) {
        List<Map<String, Object>> result = service.selectBalanceCheck(params);
        return ResponseEntity.ok(result);
    }

    /**
     * 생산수불 자체 체크 - 연속성 체크 데이터 조회
     */
    @PostMapping("/selectContinuityCheck")
    public ResponseEntity<List<Map<String, Object>>> selectContinuityCheck(@RequestBody Map<String, Object> params) {
        List<Map<String, Object>> result = service.selectContinuityCheck(params);
        return ResponseEntity.ok(result);
    }

    /**
     * 입고수불 자체 체크 - 밸런스 체크 데이터 조회
     */
    @PostMapping("/selectIncomeBalanceCheck")
    public ResponseEntity<List<Map<String, Object>>> selectIncomeBalanceCheck(@RequestBody Map<String, Object> params) {
        List<Map<String, Object>> result = service.selectIncomeBalanceCheck(params);
        return ResponseEntity.ok(result);
    }

    /**
     * 입고수불 자체 체크 - 연속성 체크 데이터 조회
     */
    @PostMapping("/selectIncomeContinuityCheck")
    public ResponseEntity<List<Map<String, Object>>> selectIncomeContinuityCheck(@RequestBody Map<String, Object> params) {
        List<Map<String, Object>> result = service.selectIncomeContinuityCheck(params);
        return ResponseEntity.ok(result);
    }

    /**
     * 입고수불 자체 체크 - 요약 정보 조회
     */
    @PostMapping("/selectIncomeSummary")
    public ResponseEntity<List<Map<String, Object>>> selectIncomeSummary(@RequestBody Map<String, Object> params) {
        List<Map<String, Object>> result = service.selectIncomeSummary(params);
        return ResponseEntity.ok(result);
    }

    /**
     * 입고수불 자체 체크 - 요약 정보 2 조회
     */
    @PostMapping("/selectIncomeSummary2")
    public ResponseEntity<List<Map<String, Object>>> selectIncomeSummary2(@RequestBody Map<String, Object> params) {
        List<Map<String, Object>> result = service.selectIncomeSummary2(params);
        return ResponseEntity.ok(result);
    }

    /**
     * 생산/입고/판매 체크 - 생산 → 재고 데이터 조회
     */
    @PostMapping("/selectProdToStock")
    public ResponseEntity<List<Map<String, Object>>> selectProdToStock(@RequestBody Map<String, Object> params) {
        List<Map<String, Object>> result = service.selectProdToStock(params);
        return ResponseEntity.ok(result);
    }

    /**
     * 생산/입고/판매 체크 - 재고 → 판매 데이터 조회
     */
    @PostMapping("/selectStockToSale")
    public ResponseEntity<List<Map<String, Object>>> selectStockToSale(@RequestBody Map<String, Object> params) {
        List<Map<String, Object>> result = service.selectStockToSale(params);
        return ResponseEntity.ok(result);
    }

    /**
     * 생산/입고/판매 체크 - 요약 정보 1 조회
     */
    @PostMapping("/selectSummary1")
    public ResponseEntity<List<Map<String, Object>>> selectSummary1(@RequestBody Map<String, Object> params) {
        List<Map<String, Object>> result = service.selectSummary1(params);
        return ResponseEntity.ok(result);
    }

    /**
     * 생산/입고/판매 체크 - 요약 정보 2 조회
     */
    @PostMapping("/selectSaleSummary2")
    public ResponseEntity<List<Map<String, Object>>> selectSaleSummary2(@RequestBody Map<String, Object> params) {
        List<Map<String, Object>> result = service.selectSaleSummary2(params);
        return ResponseEntity.ok(result);
    }

    /**
     * 제품수불 체크
     */
    // ST001: 수량수식 검증
    @PostMapping("/selectST001Detail")
    public ResponseEntity<List<Map<String, Object>>> selectST001Detail(@RequestBody Map<String, Object> params) {
        List<Map<String, Object>> result = service.selectST001Detail(params);
        return ResponseEntity.ok(result);
    }
    @PostMapping("/selectST001Summary")
    public ResponseEntity<List<Map<String, Object>>> selectST001Summary(@RequestBody Map<String, Object> params) {
        List<Map<String, Object>> result = service.selectST001Summary(params);
        return ResponseEntity.ok(result);
    }

    // ST002: 생산재고연결 검증    
    @PostMapping("/selectST002Detail")
    public ResponseEntity<List<Map<String, Object>>> selectST002Detail(@RequestBody Map<String, Object> params) {
        List<Map<String, Object>> result = service.selectST002Detail(params);
        return ResponseEntity.ok(result);
    }
    @PostMapping("/selectST002Summary")
    public ResponseEntity<List<Map<String, Object>>> selectST002Summary(@RequestBody Map<String, Object> params) {
        List<Map<String, Object>> result = service.selectST002Summary(params);
        return ResponseEntity.ok(result);
    }

    // ST003: 금액수식 검증
    @PostMapping("/selectST003Detail")
    public ResponseEntity<List<Map<String, Object>>> selectST003Detail(@RequestBody Map<String, Object> params) {
        List<Map<String, Object>> result = service.selectST003Detail(params);
        return ResponseEntity.ok(result);
    }

    @PostMapping("/selectST003Summary")
    public ResponseEntity<List<Map<String, Object>>> selectST003Summary(@RequestBody Map<String, Object> params) {
        List<Map<String, Object>> result = service.selectST003Summary(params);
        return ResponseEntity.ok(result);
    }

    // ST004: 원가항목 정합성 검증
    @PostMapping("/selectST004Detail")
    public ResponseEntity<List<Map<String, Object>>> selectST004Detail(@RequestBody Map<String, Object> params) {
        List<Map<String, Object>> result = service.selectST004Detail(params);
        return ResponseEntity.ok(result);
    }

    @PostMapping("/selectST004Summary")
    public ResponseEntity<List<Map<String, Object>>> selectST004Summary(@RequestBody Map<String, Object> params) {
        List<Map<String, Object>> result = service.selectST004Summary(params);
        return ResponseEntity.ok(result);
    }

    // ST005: 음수재고 검증
    @PostMapping("/selectST005Detail")
    public ResponseEntity<List<Map<String, Object>>> selectST005Detail(@RequestBody Map<String, Object> params) {
        List<Map<String, Object>> result = service.selectST005Detail(params);
        return ResponseEntity.ok(result);
    }
    
    @PostMapping("/selectST005Summary")
    public ResponseEntity<List<Map<String, Object>>> selectST005Summary(@RequestBody Map<String, Object> params) {
        List<Map<String, Object>> result = service.selectST005Summary(params);
        return ResponseEntity.ok(result);
    }
}
