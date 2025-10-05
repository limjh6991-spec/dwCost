/**
 * 카세트 관리 > 카세트 불출
 */
package com.dowinsys.cost.web.m0007000.mapper;

import org.apache.ibatis.annotations.Mapper;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Map;

@Repository("com.dowinsys.cost.web.m0007000.mapper.M0007001Mapper")
@Mapper
public interface M0007001Mapper {
    int checkDuplicate(Map<String, String> item);
    void deleteDuplicate(Map<String, String> item);
    List<Map<String, String>> checkDuplicateMasterList(List<Map<String, String>> list);
    int uploadExcel(List<Map<String, String>> list);
}
