/**
 * 타시스템 > 제품정보
 */
package com.dowinsys.cost.web.c0007000.mapper;

import org.apache.ibatis.annotations.Mapper;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Map;

@Repository("com.dowinsys.cost.web.c0007000.mapper.C0007004Mapper")
@Mapper
public interface C0007004Mapper {
    List<Map<String, String>> checkduplicateOrgList(List<Map<String, String>> list);

    int uploadExcel(List<Map<String, String>> list);
}
