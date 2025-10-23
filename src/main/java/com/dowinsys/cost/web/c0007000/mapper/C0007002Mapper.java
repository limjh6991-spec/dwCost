/**
 * 타시스템 > 자재투입정보
 */
package com.dowinsys.cost.web.c0007000.mapper;

import org.apache.ibatis.annotations.Mapper;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Map;

@Repository("com.dowinsys.cost.web.c0007000.mapper.C0007002Mapper")
@Mapper
public interface C0007002Mapper {
    List<Map<String, String>> checkduplicateOrgList(List<Map<String, String>> list);

    int uploadExcel(List<Map<String, String>> list);
}
