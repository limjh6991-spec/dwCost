/**
*	기준정보 > 일반코드
*/
package com.dowinsys.cost.web.c0001000.mapper;

import java.util.List;
import java.util.Map;

import org.apache.ibatis.annotations.Mapper;
import org.springframework.stereotype.Repository;

import com.dowinsys.cost.common.CamelMap;

@Repository("com.dowinsys.cost.web.c0001000.mapper.C0001007Mapper")
@Mapper
public interface C0001007Mapper {
	
	List<CamelMap<String, Object>> getMajCodeList();
	List<CamelMap<String, Object>> getCommCodeList(Map<String, Object> params);
	
	List<Map<String, Object>> checkInsertCommCode(List<Map<String, Object>> vo);
	
	int insertCommCode(Map<String, Object> params);
	int deleteCommCode(Map<String, Object> params);
	int updateCommCode(Map<String, Object> params);

}
