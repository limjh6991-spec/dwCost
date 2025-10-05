package com.dowinsys.cost.common.batch.mapper;

import java.util.Map;

import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface BatchSchedulerMapper {
	void execCalcWip(Map<String,Object> params);
	
	void execCalcDpr(Map<String,Object> params);
	
	void execCreatedFrontData(Map<String,Object> params);
	
	void execCreatedBackData(Map<String,Object> params);
}
