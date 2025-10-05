/**
*	자재관리 > 부자재 - Tray
*/
package com.dowinsys.cost.web.m0001000.mapper;

import java.util.List;
import java.util.Map;

import org.apache.ibatis.annotations.Mapper;
import org.springframework.stereotype.Repository;

import com.dowinsys.cost.common.CamelMap;

@Repository("com.dowinsys.cost.web.m0001000.mapper.M0001005Mapper")
@Mapper
public interface M0001005Mapper {
	
	List<Map<String, Object>> checkInsertInData(List<Map<String, Object>> vo);
	List<Map<String, Object>> checkUseInData(List<Map<String, Object>> vo);
	CamelMap<String, Object> checkRemainQty(Map<String, Object> vo); 
	CamelMap<String, Object> checkRemainDiffQty(Map<String, Object> vo);
	int insertOutData(Map<String, Object> params); 
	int updateOutData(Map<String, Object> params); 
	int deleteOutData(Map<String, Object> params); 
	int updateRemainQtyMinus(Map<String, Object> params); 
	int updateRemainQtyPlus(Map<String, Object> params);
	int updateRemainDiffQty(Map<String, Object> params);	
	
	// 재고실사
	Integer selectConfirmN(Map<String, Object> params);
	int deleteSubMatTrayIdStock(Map<String, Object> params);
	int insertSubMatTrayIdStock(Map<String, Object> params);
	int updateSubMatTrayIdStock(Map<String, Object> params);
	int deleteSubMatTrayStock(Map<String, Object> params);
	int insertSubMatTrayStock(Map<String, Object> params);
	int updateSubMatTrayStock(Map<String, Object> params); 
	
	// Tray Code별 필름정보
	List<Map<String, Object>> checkTrayCodeData(List<Map<String, Object>> vo);
	
	void createTempMatStockTable(Map<String, Object> params);
	void dropTempMatStockTable(Map<String, Object> params);	
	

}
