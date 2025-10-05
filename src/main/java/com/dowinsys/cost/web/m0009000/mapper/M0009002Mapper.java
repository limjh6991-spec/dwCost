/**
*	설비관리 > 비가동 실적 관리
*/
package com.dowinsys.cost.web.m0009000.mapper;

import java.util.List;
import java.util.Map;

import org.apache.ibatis.annotations.Mapper;
import org.springframework.stereotype.Repository;

import com.dowinsys.cost.common.CamelMap;

@Repository("com.dowinsys.cost.web.m0009000.mapper.M0009002Mapper")
@Mapper
public interface M0009002Mapper {
	
	int deleteEquipOffLog(Map<String, Object> params);
	int insertEquipOffLog(Map<String, Object> params);
	int updateEquipOffLog(Map<String, Object> params);
	List<CamelMap<String, Object>> checkEndOffDate(Map<String, Object> params);
	List<CamelMap<String, Object>> checkDupOffDate(Map<String, Object> params);
	List<CamelMap<String, Object>> checkDupOffDateForUpdate(Map<String, Object> params);
	
}
