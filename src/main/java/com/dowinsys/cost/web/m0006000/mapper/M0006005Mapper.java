/**
*	기준정보 > 불량사유 코드
*/
package com.dowinsys.cost.web.m0006000.mapper;

import java.util.List;
import java.util.Map;

import org.apache.ibatis.annotations.Mapper;
import org.springframework.stereotype.Repository;

import com.dowinsys.cost.common.CamelMap;

@Repository("com.dowinsys.cost.web.m0006000.mapper.M0006005Mapper")
@Mapper
public interface M0006005Mapper {

	List<CamelMap<String, Object>> getDefectCdList(Map<String, Object> params);
	
	List<Map<String, Object>> checkInsertDefectCd(List<Map<String, Object>> vo);
	
	int insertDefectCd(Map<String, Object> params);
	int deleteDefectCd(Map<String, Object> params);
	int updateDefectCd(Map<String, Object> params);
	
}
