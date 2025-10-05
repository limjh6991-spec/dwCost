/**
*	기준정보 > 일반코드
*/
package com.dowinsys.cost.web.m0006000.service;

import java.util.List;
import java.util.Map;

import com.dowinsys.cost.common.CamelMap;
import com.dowinsys.cost.common.generic.vo.GenericResourceVo;

public interface M0006002Service {
	
	List<CamelMap<String, Object>> getMajCdList();
	
	Map<String, Object> saveData(GenericResourceVo vo);
	
}
