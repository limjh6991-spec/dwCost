/**
*	자재관리 > 부자재 - 더미글라스
*/
package com.dowinsys.cost.web.m0001000.mapper;

import java.util.List;
import java.util.Map;

import org.apache.ibatis.annotations.Mapper;
import org.springframework.stereotype.Repository;

import com.dowinsys.cost.common.CamelMap;

@Repository("com.dowinsys.cost.web.m0001000.mapper.M0001008Mapper")
@Mapper
public interface M0001008Mapper {
	
	List<Map<String, Object>> checkInsertInData(List<Map<String, Object>> vo);
	List<Map<String, Object>> checkUseInData(List<Map<String, Object>> vo);
	CamelMap<String, Object> checkRemainQty(Map<String, Object> vo);
	CamelMap<String, Object> checkRemainDiffQty(Map<String, Object> vo);
	
	String insertOutData(Map<String, Object> params);
	int updateOutData(Map<String, Object> params); 
	int deleteOutData(Map<String, Object> params);
	int updateRemainQtyMinus(Map<String, Object> params); 
	int updateRemainQtyPlus(Map<String, Object> params);
	int updateRemainDiffQty(Map<String, Object> params);	
	
	// 재고실사
	Integer selectConfirmN(Map<String, Object> params);
	int deleteSubMatDummyIdStock(Map<String, Object> params);
	int insertSubMatDummyIdStock(Map<String, Object> params);	
	int updateSubMatDummyIdStock(Map<String, Object> params);
	int deleteSubMatDummyStock(Map<String, Object> params);
	int insertSubMatDummyStock(Map<String, Object> params);
	int updateSubMatDummyStock(Map<String, Object> params);
	
	void createTempMatStockTable(Map<String, Object> params);
	void dropTempMatStockTable(Map<String, Object> params);	

}
