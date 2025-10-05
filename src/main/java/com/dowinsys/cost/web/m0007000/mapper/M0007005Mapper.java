/**
 * 카세트 관리 > 카세트 마스터
 */
package com.dowinsys.cost.web.m0007000.mapper;

import org.apache.ibatis.annotations.Mapper;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Map;

@Repository("com.dowinsys.cost.web.m0007000.mapper.M0007005Mapper")
@Mapper
public interface M0007005Mapper {
    int uploadExcel(Map<String, String> item);
    int uploadExcelUpdate(Map<String, String> item);
}
