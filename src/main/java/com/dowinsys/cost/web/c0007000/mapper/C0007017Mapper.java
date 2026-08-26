/**
 * 타시스템 > 기타입출고금액 (본사, DOI_ETC_INOUT)
 */
package com.dowinsys.cost.web.c0007000.mapper;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Map;

@Repository("com.dowinsys.cost.web.c0007000.mapper.C0007017Mapper")
@Mapper
public interface C0007017Mapper {
    int deleteMonth(@Param("yyyymm") String yyyymm);
    int uploadExcel(List<Map<String, String>> list);
}
