/**
*	기준정보 > 거래처 마스터
*/
package com.dowinsys.cost.web.m0006000.mapper;

import java.util.List;
import java.util.Map;

import org.apache.ibatis.annotations.Mapper;
import org.springframework.stereotype.Repository;

@Repository("com.dowinsys.cost.web.m0006000.mapper.M0006003Mapper")
@Mapper
public interface M0006003Mapper {
	
	List<Map<String, Object>> checkInsertVendorMst(List<Map<String, Object>> vo);
	
	int insertVendorMst(Map<String, Object> params);
	int deleteVendorMst(Map<String, Object> params);
	int updateVendorMst(Map<String, Object> params);

}
