/**
 * 기준정보 > 원가기준정보
 */
package com.dowinsys.cost.web.c0001000.mapper;

import com.dowinsys.cost.common.CamelMap;
import org.apache.ibatis.annotations.Mapper;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Map;

@Repository("com.dowinsys.cost.web.c0001000.mapper.C0001004Mapper")
@Mapper
public interface C0001004Mapper {
    //Tab1
    List<Map<String, String>> checkTab1DuplicateOrgList(List<Map<String, String>> list);
    int tab1UploadExcel(List<Map<String, String>> list);

    // Tab2
    List<Map<String, String>> checkTab2DuplicateOrgList(List<Map<String, String>> list);
    int tab2UploadExcel(List<Map<String, String>> list);

    // Tab3
    List<Map<String, String>> checkTab3DuplicateOrgList(List<Map<String, String>> list);
    int tab3UploadExcel(List<Map<String, String>> list);

    // Tab5
    List<Map<String, String>> checkTab5DuplicateOrgList(List<Map<String, String>> list);
    int tab5UploadExcel(List<Map<String, String>> list);
}
