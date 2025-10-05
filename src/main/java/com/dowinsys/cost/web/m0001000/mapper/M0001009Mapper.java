/**
*	자재관리 > 포장재
*/
package com.dowinsys.cost.web.m0001000.mapper;

import java.util.List;
import java.util.Map;

import org.apache.ibatis.annotations.Mapper;
import org.springframework.stereotype.Repository;

import com.dowinsys.cost.common.CamelMap;

@Repository("com.dowinsys.cost.web.m0001000.mapper.M0001009Mapper")
@Mapper
public interface M0001009Mapper {
	
	List<Map<String, Object>> checkUseInData(List<Map<String, Object>> vo);
	CamelMap<String, Object> selectEtcInfo(Map<String, Object> vo);
	
	String insertOutData(Map<String, Object> params); 
	int insertOutDetailData(Map<String, Object> params);
	int updateOutData(Map<String, Object> params); 
	int deleteOutData(Map<String, Object> params); 
	int deleteOutDetailData(Map<String, Object> params);	
	int updateRemainQtyMinus(Map<String, Object> params); 
	int updateRemainQtyPlus(Map<String, Object> params);	
	int deletetMatCloseInfo(Map<String, Object> params);
	int insertMatCloseInfo(Map<String, Object> params);	
	int updatetMatCloseInfo(Map<String, Object> params);	
	
	// 재고실사
	String selectPreStockStatus(Map<String, Object> params);
	Integer selectConfirmN(Map<String, Object> params);
	int deleteSubMatEtcStock(Map<String, Object> params);
	int insertSubMatEtcStock(Map<String, Object> params);
	int updateSubMatEtcStock(Map<String, Object> params); 	
	// 관리 품목
	List<Map<String, Object>> checkUsedInMatCategoryData(List<Map<String, Object>> vo);
	List<Map<String, Object>> checkMatCategoryData(List<Map<String, Object>> vo);
	
	void createTempMatStockTable(Map<String, Object> params);
	void dropTempMatStockTable(Map<String, Object> params);		
	
	

}
