/**
*	자재관리 > 부자재 - Tool
*/
package com.dowinsys.cost.web.m0001000.mapper;

import java.util.List;
import java.util.Map;

import org.apache.ibatis.annotations.Mapper;
import org.springframework.stereotype.Repository;

import com.dowinsys.cost.common.CamelMap;

@Repository("com.dowinsys.cost.web.m0001000.mapper.M0001003Mapper")
@Mapper
public interface M0001003Mapper {
	
	List<Map<String, Object>> checkInsertInData(List<Map<String, Object>> vo);	
	List<Map<String, Object>> checkUseInData(List<Map<String, Object>> vo);
	CamelMap<String, Object> checkRemainQty(Map<String, Object> vo); 
	CamelMap<String, Object> checkEquipTool(Map<String, Object> vo);
	int insertOutData(Map<String, Object> params);
	int updateOutData(Map<String, Object> params);
	int deleteOutData(Map<String, Object> params);
	int updateRemainQtyMinus(Map<String, Object> params);
	int updateRemainQtyPlus(Map<String, Object> params);
	
	// 재고실사
	Integer selectConfirmN(Map<String, Object> params);
	int deleteSubMatToolIdStock(Map<String, Object> params);
	int insertSubMatToolIdStock(Map<String, Object> params);
	int updateSubMatToolIdStock(Map<String, Object> params);
	int deleteSubMatToolStock(Map<String, Object> params);
	int insertSubMatToolStock(Map<String, Object> params);
	int updateSubMatToolStock(Map<String, Object> params);
	
	void createTempMatStockTable(Map<String, Object> params);
	void dropTempMatStockTable(Map<String, Object> params);	

}
