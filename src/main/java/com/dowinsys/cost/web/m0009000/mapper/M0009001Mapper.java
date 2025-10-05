/**
*	설비관리 > 설비 기준정보
*/
package com.dowinsys.cost.web.m0009000.mapper;

import java.util.List;
import java.util.Map;

import org.apache.ibatis.annotations.Mapper;
import org.springframework.stereotype.Repository;

import com.dowinsys.cost.common.CamelMap;

@Repository("com.dowinsys.cost.web.m0009000.mapper.M0009001Mapper")
@Mapper
public interface M0009001Mapper {
	
	List<CamelMap<String, Object>> checkApplyDate(List<Map<String, Object>> vo);		
	List<CamelMap<String, Object>> checkApplyDateForUpdate(Map<String, Object> vo);
	
	List<CamelMap<String, Object>> checkExistsOffCode(List<Map<String, Object>> vo);
	List<CamelMap<String, Object>> checkUsedOffCode(List<Map<String, Object>> vo);
	
}
