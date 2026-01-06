/**
 * 타시스템 > 유상사급
 */
package com.dowinsys.cost.web.c0007000.mapper;

import org.apache.ibatis.annotations.Mapper;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Map;

@Repository("com.dowinsys.cost.web.c0007000.mapper.C0007007Mapper")
@Mapper
public interface C0007007Mapper {
    List<Map<String, String>> checkTab1DuplicateOrgList(List<Map<String, String>> list);
    int tab1UploadExcel(List<Map<String, String>> list);

    List<Map<String, String>> checkTab2DuplicateOrgList(List<Map<String, String>> list);
    int tab2UploadExcel(List<Map<String, String>> list);
}
