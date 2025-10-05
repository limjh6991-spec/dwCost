/**
*	자재관리 > 부자재 - 약액
*/
package com.dowinsys.cost.web.m0001000.mapper;

import java.util.List;
import java.util.Map;

import org.apache.ibatis.annotations.Mapper;
import org.springframework.stereotype.Repository;

import com.dowinsys.cost.common.CamelMap;

@Repository("com.dowinsys.cost.web.m0001000.mapper.M0001006Mapper")
@Mapper
public interface M0001006Mapper {
	
	List<Map<String, Object>> checkInsertInData(List<Map<String, Object>> vo);
	List<Map<String, Object>> checkUseInData(List<Map<String, Object>> vo);
	CamelMap<String, Object> checkRemainQty(Map<String, Object> vo); 
	CamelMap<String, Object> checkRemainDiffQty(Map<String, Object> vo);
	CamelMap<String, Object> checkExistsReturnData(Map<String, Object> vo);
	int checkOrgReturnQty(Map<String, Object> params); 
	
	int insertOutData(Map<String, Object> params); 
	int updateOutData(Map<String, Object> params); 
	int deleteOutData(Map<String, Object> params); 
	int updateRemainQtyMinus(Map<String, Object> params); 
	int updateRemainQtyPlus(Map<String, Object> params);
	int updateRemainDiffQty(Map<String, Object> params);
	
	int insertReturnData(Map<String, Object> params); 
	int updateReturnData(Map<String, Object> params);	 	
	int deleteReturnData(Map<String, Object> params);
	int updateReturnQtyForOuData(Map<String, Object> params);
	int updateReturnQtyZeroForOuData(Map<String, Object> params);
	int updateRemainQtyMinusForReturn(Map<String, Object> params);
	int updateRemainQtyPlusForReturn(Map<String, Object> params);
	int updateRemainDiffQtyForReturn(Map<String, Object> params);	
	
	// 재고실사
	Integer selectConfirmN(Map<String, Object> params);
	int deleteSubMatChemicalIdStock(Map<String, Object> params);
	int insertSubMatChemicalIdStock(Map<String, Object> params);
	int updateSubMatChemicalIdStock(Map<String, Object> params);
	int deleteSubMatChemicalStock(Map<String, Object> params);
	int insertSubMatChemicalStock(Map<String, Object> params);
	int updateSubMatChemicalStock(Map<String, Object> params); 
	
	void createTempMatStockTable(Map<String, Object> params);
	void dropTempMatStockTable(Map<String, Object> params);	

}
