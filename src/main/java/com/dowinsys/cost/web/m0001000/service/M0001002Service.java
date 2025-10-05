/**
*	자재관리 > 부자재-레진
*/
package com.dowinsys.cost.web.m0001000.service;

import java.util.Map;

import com.dowinsys.cost.common.generic.vo.GenericResourceVo;

public interface M0001002Service {
	
	Map<String, Object> getInBaseInfo(Map<String, Object> params);
	
	Map<String, Object> saveInData(GenericResourceVo grv);
	
	Map<String, Object> saveOutData(GenericResourceVo grv);
	
	Map<String, Object> saveSummaryData(Map<String, Object> params);
	Map<String, Object> saveStockIdData(GenericResourceVo grv);

}
