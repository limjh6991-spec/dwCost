/**
*	자재관리 > 부자재 - 필터
*/
package com.dowinsys.cost.web.m0001000.service;

import java.util.Map;

import com.dowinsys.cost.common.generic.vo.GenericResourceVo;

public interface M0001007Service {
	
	Map<String, Object> saveInData(GenericResourceVo vo);
	Map<String, Object> saveOutData(GenericResourceVo vo);	
	
	Map<String, Object> saveSummaryData(Map<String, Object> params);
	Map<String, Object> saveStockData(GenericResourceVo grv);		

}
