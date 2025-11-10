/**
 * 타시스템 I/F & Upload > 생산/입고/판매 체크
 */
package com.dowinsys.cost.web.c0007000.mapper;

import org.apache.ibatis.annotations.Mapper;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Map;

@Repository("com.dowinsys.cost.web.c0007000.mapper.C0007008Mapper")
@Mapper
public interface C0007008Mapper {
    List<Map<String, Object>> selectProdToStock(Map<String, Object> params);
    
    List<Map<String, Object>> selectStockToSale(Map<String, Object> params);
    
    List<Map<String, Object>> selectSummary1(Map<String, Object> params);
    
    List<Map<String, Object>> selectSummary2(Map<String, Object> params);
}
