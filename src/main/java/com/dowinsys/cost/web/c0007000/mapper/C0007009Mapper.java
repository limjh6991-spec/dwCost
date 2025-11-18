/**
 * 타시스템 I/F & Upload > 불량반품
 */
package com.dowinsys.cost.web.c0007000.mapper;

import org.apache.ibatis.annotations.Mapper;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Map;

@Repository("com.dowinsys.cost.web.c0007000.mapper.C0007009Mapper")
@Mapper
public interface C0007009Mapper {

    List<Map<String, Object>> selectRmaData(Map<String, Object> param);

    int insertRmaData(Map<String, Object> param);

    int updateRmaData(Map<String, Object> param);

    int deleteRmaData(Map<String, Object> param);

    List<Map<String, Object>> selectModelPopup(Map<String, Object> param);
}