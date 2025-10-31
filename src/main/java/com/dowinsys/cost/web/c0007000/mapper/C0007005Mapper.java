/**
 * 타시스템 > 매출 정보
 */
package com.dowinsys.cost.web.c0007000.mapper;

import org.apache.ibatis.annotations.Mapper;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Map;

@Repository("com.dowinsys.cost.web.c0007000.mapper.C0007005Mapper")
@Mapper
public interface C0007005Mapper {
    int uploadExcel(List<Map<String, String>> list);
}
