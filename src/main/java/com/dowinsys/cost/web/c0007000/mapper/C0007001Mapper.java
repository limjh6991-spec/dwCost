/**
 * 타시스템 > 부서별,계정별 비용
 */
package com.dowinsys.cost.web.c0007000.mapper;

import org.apache.ibatis.annotations.Mapper;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Map;

@Repository("com.dowinsys.cost.web.c0007000.mapper.C0007001Mapper")
@Mapper
public interface C0007001Mapper {
    List<Map<String, String>> checkduplicateOrgList(List<Map<String, String>> list);

    int uploadExcel(List<Map<String, String>> list);
}
