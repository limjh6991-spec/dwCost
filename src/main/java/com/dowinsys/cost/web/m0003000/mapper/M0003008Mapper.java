/**
*	제조 실적 입력 > Rework
*/
package com.dowinsys.cost.web.m0003000.mapper;

import java.util.Map;

import org.apache.ibatis.annotations.Mapper;
import org.springframework.stereotype.Repository;

@Repository("com.dowinsys.cost.web.m0003000.mapper.M0003008Mapper")
@Mapper
public interface M0003008Mapper {
	int updateEndJobVLR(Map<String, Object> params);
	int insertReworkCst(Map<String, Object> params);
	void insertReworkBadCnt(Map<String, Object> params);
}
