/**
 * 제조매출원가 > 제품수불 체크
 */
package com.dowinsys.cost.web.c0003000.mapper;

import org.apache.ibatis.annotations.Mapper;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Map;

@Repository("com.dowinsys.cost.web.c0003000.mapper.C0003010Mapper")
@Mapper
public interface C0003010Mapper {
    // ST001: 수량수식 검증
    List<Map<String, Object>> selectST001Detail(Map<String, Object> params);
    List<Map<String, Object>> selectST001Summary(Map<String, Object> params);
    
    // ST002: 생산재고연결 검증
    List<Map<String, Object>> selectST002Detail(Map<String, Object> params);
    List<Map<String, Object>> selectST002Summary(Map<String, Object> params);
    
    // ST003: 금액수식 검증
    List<Map<String, Object>> selectST003Detail(Map<String, Object> params);
    List<Map<String, Object>> selectST003Summary(Map<String, Object> params);
    
    // ST004: 원가항목 정합성 검증
    List<Map<String, Object>> selectST004Detail(Map<String, Object> params);
    List<Map<String, Object>> selectST004Summary(Map<String, Object> params);
    
    // ST005: 음수재고 검증
    List<Map<String, Object>> selectST005Detail(Map<String, Object> params);
    List<Map<String, Object>> selectST005Summary(Map<String, Object> params);
}
