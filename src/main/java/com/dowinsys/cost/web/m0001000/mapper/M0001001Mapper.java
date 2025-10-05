/**
*	자재관리 > 원자재
*/
package com.dowinsys.cost.web.m0001000.mapper;

import java.util.List;
import java.util.Map;

import org.apache.ibatis.annotations.Mapper;
import org.springframework.stereotype.Repository;

import com.dowinsys.cost.common.CamelMap;

@Repository("com.dowinsys.cost.web.m0001000.mapper.M0001001Mapper")
@Mapper
public interface M0001001Mapper {
	
	int dupGlassId(Map<String, Object> params);
	CamelMap<String, Object> getGlassInfo(Map<String, Object> params);
	CamelMap<String, Object> getCutDateInfo(Map<String, Object> params);
	CamelMap<String, Object> getUnitInfo(Map<String, Object> params);
	
	List<CamelMap<String, Object>> getRawMatInList(Map<String, Object> params);
	
	List<Map<String, Object>> checkDupGlassId(List<Map<String, Object>> vo);
	List<Map<String, Object>> checkUseInData(List<Map<String, Object>> vo);
	
	int insertRawMatIn(Map<String, Object> params);
	int deleteRawMatIn(Map<String, Object> params);
	int updateRawMatIn(Map<String, Object> params);
	
	
	CamelMap<String, Object> getRawMatInInfo(Map<String, Object> params);
	
	List<CamelMap<String, Object>> getRawMatOutList(Map<String, Object> params);

	
	CamelMap<String, Object> checkRemainQty(Map<String, Object> params);
	CamelMap<String, Object> checkRemainDiffQty(Map<String, Object> vo);
	
	int insertRawMatOut(Map<String, Object> params);
	int updateRemainQtyMinus(Map<String, Object> params);
	int deleteRawMatOut(Map<String, Object> params);
	int updateRemainQtyPlus(Map<String, Object> params);
	int updateRawMatOut(Map<String, Object> params);
	int updateRemainDiffQty(Map<String, Object> params);
	
	// 재고실사
	String selectPreStockStatus(Map<String, Object> params);
	Integer selectConfirmN(Map<String, Object> params);
	int deleteRawMatIdStock(Map<String, Object> params);
	int insertRawMatIdStock(Map<String, Object> params);
	int updateRawMatIdStock(Map<String, Object> params);
	int deleteRawMatStock(Map<String, Object> params);
	int insertRawMatStock(Map<String, Object> params);
	int updateRawMatStock(Map<String, Object> params);
	int deletetMatCloseInfo(Map<String, Object> params);
	int insertMatCloseInfo(Map<String, Object> params);	
	int updatetMatCloseInfo(Map<String, Object> params);
	
	List<CamelMap<String, Object>> selectRawMatMonthReport(Map<String, Object> params);
	
	List<Map<String, Object>> checkDupGlassMst(List<Map<String, Object>> vo);
	int insertGlassMst(Map<String, Object> params);
	int deleteGlassMst(Map<String, Object> params);
	int updateGlassMst(Map<String, Object> params);
	
	void createTempMatStockTable(Map<String, Object> params);
	void dropTempMatStockTable(Map<String, Object> params);
	
}
