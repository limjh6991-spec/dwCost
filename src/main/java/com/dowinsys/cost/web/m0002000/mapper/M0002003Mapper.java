/**
*	프로세스 플래닝 > 제품 모델 관리
*/
package com.dowinsys.cost.web.m0002000.mapper;

import org.apache.ibatis.annotations.Mapper;
import org.springframework.stereotype.Repository;

import com.dowinsys.cost.common.CamelMap;
import com.dowinsys.cost.common.generic.vo.GenericResourceVo;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Repository("com.dowinsys.cost.web.m0002000.mapper.M0002003Mapper")
@Mapper
public interface M0002003Mapper {
	
	//List<Map<String, Object>> checkDeleteProdProc(List<Map<String, Object>> vo);
	List<Map<String, Object>> checkInsertProdProc(List<Map<String, Object>> vo);
	List<Map<String, Object>> checkDeleteProcess(List<Map<String, Object>> vo);
	List<Map<String, Object>> checkInsertProcess(List<Map<String, Object>> vo);
	//List<Map<String, Object>> checkDeleteProcessPlan(List<Map<String, Object>> vo);
	List<Map<String, Object>> checkInsertProcessPlan(List<Map<String, Object>> vo);
	List<Map<String, Object>> checkDeleteStep(List<Map<String, Object>> vo);
	List<Map<String, Object>> checkInsertStep(List<Map<String, Object>> vo);
}
