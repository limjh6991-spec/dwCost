/**
 * 타시스템 I/F & Upload > 생산수불 자체 체크
 */
package com.dowinsys.cost.web.c0007000.mapper;

import org.apache.ibatis.annotations.Mapper;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Map;

@Repository("com.dowinsys.cost.web.c0007000.mapper.C0007006Mapper")
@Mapper
public interface C0007006Mapper {
    List<Map<String, Object>> selectBalanceCheck(Map<String, Object> params);
    
    List<Map<String, Object>> selectSummary(Map<String, Object> params);
}
