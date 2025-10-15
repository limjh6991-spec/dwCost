/**
 * 기준정보 > 설비관리
 */
package com.dowinsys.cost.web.c0001000.mapper;

import org.apache.ibatis.annotations.Mapper;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Map;

@Repository("com.dowinsys.cost.web.c0001000.mapper.C0001001Mapper")
@Mapper
public interface C0001001Mapper {
    List<Map<String, String>> checkduplicateOrgList(List<Map<String, String>> list);

    int uploadExcel(List<Map<String, String>> list);
}
