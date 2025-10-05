/**
*	제조 실적 입력 > FRONT
*/
package com.dowinsys.cost.web.m0003000.mapper;

import java.util.Map;

import org.apache.ibatis.annotations.Mapper;
import org.springframework.stereotype.Repository;

@Repository("com.dowinsys.cost.web.m0003000.mapper.M0003005Mapper")
@Mapper
public interface M0003005Mapper {
	void execCalcWipNow(Map<String, Object> params);
	void execCalcDprNow(Map<String, Object> params);
	
}
