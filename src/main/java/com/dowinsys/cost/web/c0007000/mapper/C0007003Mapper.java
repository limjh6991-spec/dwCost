/**
 * 기준정보 > 설비관리
 */
package com.dowinsys.cost.web.c0007000.mapper;

import org.apache.ibatis.annotations.Mapper;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Map;

@Repository("com.dowinsys.cost.web.c0007000.mapper.C0007003Mapper")
@Mapper
public interface C0007003Mapper {
    List<Map<String, String>> checkTab2DuplicateOrgList(List<Map<String, String>> list);
    int tab2UploadExcel(List<Map<String, String>> list);
}
