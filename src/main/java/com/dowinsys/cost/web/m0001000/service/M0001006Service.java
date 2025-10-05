/**
*	자재관리 > 부자재 - 약액
*/
package com.dowinsys.cost.web.m0001000.service;

import java.util.Map;

import com.dowinsys.cost.common.generic.vo.GenericResourceVo;

public interface M0001006Service {
	
	Map<String, Object> saveInData(GenericResourceVo vo);
	Map<String, Object> saveOutData(GenericResourceVo vo);
	Map<String, Object> saveReturnData(GenericResourceVo vo);
	
	Map<String, Object> saveSummaryData(Map<String, Object> params);
	Map<String, Object> saveStockIdData(GenericResourceVo grv);	

}
