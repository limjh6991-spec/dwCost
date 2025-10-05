/**
*	자재관리 > 부자재 - 필름
*/
package com.dowinsys.cost.web.m0001000.mapper;

import java.util.List;
import java.util.Map;

import org.apache.ibatis.annotations.Mapper;
import org.springframework.stereotype.Repository;

import com.dowinsys.cost.common.CamelMap;

@Repository("com.dowinsys.cost.web.m0001000.mapper.M0001004Mapper")
@Mapper
public interface M0001004Mapper {
	
	
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
	 // int updateMatFilmError(Map<String, Object> params); 
	  
		// 재고실사
	    Integer selectConfirmN(Map<String, Object> params);
		int deleteSubMatFilmIdStock(Map<String, Object> params);
		int insertSubMatFilmIdStock(Map<String, Object> params);
		int updateSubMatFilmIdStock(Map<String, Object> params);
		int deleteSubMatFilmStock(Map<String, Object> params);
		int insertSubMatFilmStock(Map<String, Object> params);
		int updateSubMatFilmStock(Map<String, Object> params); 
		
		// Model별 필름정보
		List<Map<String, Object>> checkModelData(List<Map<String, Object>> vo);
		
		void createTempMatStockTable(Map<String, Object> params);
		void dropTempMatStockTable(Map<String, Object> params);		

}
