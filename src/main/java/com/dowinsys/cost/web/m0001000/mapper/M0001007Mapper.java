/**
*	자재관리 > 부자재 - 필터
*/
package com.dowinsys.cost.web.m0001000.mapper;

import java.util.List;
import java.util.Map;

import org.apache.ibatis.annotations.Mapper;
import org.springframework.stereotype.Repository;

import com.dowinsys.cost.common.CamelMap;

@Repository("com.dowinsys.cost.web.m0001000.mapper.M0001007Mapper")
@Mapper
public interface M0001007Mapper {
	
	List<Map<String, Object>> checkUseInData(List<Map<String, Object>> vo);
	CamelMap<String, Object> selectFilterInfo(Map<String, Object> vo);
	
	String insertOutData(Map<String, Object> params); 
	int insertOutDetailData(Map<String, Object> params);
	int updateOutData(Map<String, Object> params); 
	int deleteOutData(Map<String, Object> params); 
	int deleteOutDetailData(Map<String, Object> params);	
	int updateRemainQtyMinus(Map<String, Object> params); 
	int updateRemainQtyPlus(Map<String, Object> params);	
	
	// 재고실사
	Integer selectConfirmN(Map<String, Object> params);
	int deleteSubMatFilterStock(Map<String, Object> params);
	int insertSubMatFilterStock(Map<String, Object> params);
	int updateSubMatFilterStock(Map<String, Object> params); 	
	int insertSubMatFilterEquipOut(Map<String, Object> params);
	int deleteSubMatFilterEquipOut(Map<String, Object> params);
	
	void createTempMatStockTable(Map<String, Object> params);
	void dropTempMatStockTable(Map<String, Object> params);	

}
