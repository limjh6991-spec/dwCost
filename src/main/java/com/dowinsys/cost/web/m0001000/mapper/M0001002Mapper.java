/**
*	자재관리 > 부자재-레진
*/
package com.dowinsys.cost.web.m0001000.mapper;

import java.util.List;
import java.util.Map;

import org.apache.ibatis.annotations.Mapper;
import org.springframework.stereotype.Repository;

import com.dowinsys.cost.common.CamelMap;

@Repository("com.dowinsys.cost.web.m0001000.mapper.M0001002Mapper")
@Mapper
public interface M0001002Mapper {
	
	int dupMaterialId(Map<String, Object> params);
	CamelMap<String, Object> getResinInfo(Map<String, Object> params);
	CamelMap<String, Object> getUnitInfo(Map<String, Object> params);
	
	List<CamelMap<String, Object>> getSubMatResinInList(Map<String, Object> params);
	
	List<Map<String, Object>> checkDupResinId(List<Map<String, Object>> vo);
	List<Map<String, Object>> checkUseInData(List<Map<String, Object>> vo);
	CamelMap<String, Object> checkRemainQty(Map<String, Object> vo);
	
	int insertSubMatResinIn(Map<String, Object> params);
	int deleteSubMatResinIn(Map<String, Object> params);
	int updateSubMatResinIn(Map<String, Object> params);
	
	CamelMap<String, Object> getSubMatResinInInfo(Map<String, Object> params);
	
	List<CamelMap<String, Object>> getSubMatResinOutList(Map<String, Object> params);

	
	List<Map<String, Object>> checkDupResinOut(List<Map<String, Object>> vo);
	
	int insertSubMatResinOut(Map<String, Object> params);
	int updateSubMatResinOut(Map<String, Object> params);	
	int deleteSubMatResinOut(Map<String, Object> params);
	int updateRemainQtyMinus(Map<String, Object> params);
	int updateRemainQtyPlus(Map<String, Object> params);
	
	// 재고실사
	Integer selectConfirmN(Map<String, Object> params);
	int deleteSubMatResinIdStock(Map<String, Object> params);
	int insertSubMatResinIdStock(Map<String, Object> params);
	int updateSubMatResinIdStock(Map<String, Object> params);
	int deleteSubMatResinStock(Map<String, Object> params);
	int insertSubMatResinStock(Map<String, Object> params);
	int updateSubMatResinStock(Map<String, Object> params);	
	int insertSubMatResinEquipOut(Map<String, Object> params);
	int deleteSubMatResinEquipOut(Map<String, Object> params);
	
	void createTempMatStockTable(Map<String, Object> params);
	void dropTempMatStockTable(Map<String, Object> params);	

}
