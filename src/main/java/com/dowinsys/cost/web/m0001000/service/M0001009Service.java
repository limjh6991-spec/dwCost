/**
*	자재관리 > 포장재
*/
package com.dowinsys.cost.web.m0001000.service;

import java.util.Map;

import com.dowinsys.cost.common.generic.vo.GenericResourceVo;

public interface M0001009Service {
	
	Map<String, Object> saveInData(GenericResourceVo vo);
	Map<String, Object> saveOutData(GenericResourceVo vo);	
	
	Map<String, Object> saveSummaryData(Map<String, Object> params);
	Map<String, Object> saveStockData(GenericResourceVo grv);		
	
	Map<String, Object> saveMatCategoryData(GenericResourceVo grv);

}
