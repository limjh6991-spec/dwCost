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

    Map<String, Object> checkCurrentMonthData(Map<String, Object> param);
    Map<String, Object> checkPrevMonthData(Map<String, Object> param);

    //Tab1
    List<Map<String, String>> checkTab1DuplicateOrgList(List<Map<String, String>> list);
    int tab1UploadExcel(List<Map<String, String>> list);

    // Tab2
    List<Map<String, String>> checkTab2DuplicateOrgList(List<Map<String, String>> list);
    int tab2UploadExcel(List<Map<String, String>> list);

    // Tab3
    List<Map<String, String>> checkTab3DuplicateOrgList(List<Map<String, String>> list);
    int tab3UploadExcel(List<Map<String, String>> list);

    // Tab4
    List<Map<String, String>> checkTab4DuplicateOrgList(List<Map<String, String>> list);
    int tab4UploadExcel(List<Map<String, String>> list);

    // Tab1
    int countTab1ByYyyymmAndSite(Map<String, Object> param);
    List<Map<String, Object>> selectTab1ByYyyymmAndSite(Map<String, Object> param);

    // Tab2
    int countTab2ByYyyymmAndSite(Map<String, Object> param);
    List<Map<String, Object>> selectTab2ByYyyymmAndSite(Map<String, Object> param);

    // Tab3
    int countTab3ByYyyymmAndSite(Map<String, Object> param);
    List<Map<String, Object>> selectTab3ByYyyymmAndSite(Map<String, Object> param);

    // Tab4 - 데이터 생성
    int countTab4ModelByYyyymmAndSite(Map<String, Object> param);
    int callGenDoiModelMastProcedure(Map<String, Object> param);
}
