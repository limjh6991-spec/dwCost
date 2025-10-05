/**
*	프로세스 플래닝 > SITE 모델링 관리
*/
package com.dowinsys.cost.web.m0002000.service.impl;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.dowinsys.cost.common.CamelMap;
import com.dowinsys.cost.common.generic.service.GenericResourceService;
import com.dowinsys.cost.common.generic.vo.GenericResourceVo;
import com.dowinsys.cost.common.generic.vo.QueryData;
import com.dowinsys.cost.web.m0002000.mapper.M0002001Mapper;
import com.dowinsys.cost.web.m0002000.service.M0002001Service;

@Service("com.dowinsys.cost.web.m0002000.service.M0002001")
public class M0002001ServiceImpl implements M0002001Service {

	@Autowired
	M0002001Mapper mapper;
	
	@Autowired
	GenericResourceService genericService;	
	
	public List<CamelMap<String, Object>> getLineList() {
		List<CamelMap<String, Object>> dt =  mapper.selectLineList();		
		return dt;
	}
	
	public List<CamelMap<String, Object>> getAreaList() {
		List<CamelMap<String, Object>> dt =  mapper.selectAreaList();		
		return dt;
	}
	
	public List<CamelMap<String, Object>> getEquipList() {
		List<CamelMap<String, Object>> dt =  mapper.selectEquipList();		
		return dt;
	}	
	
	public Map<String, Object> saveAreaData(GenericResourceVo grv) {
		
		Map<String, Object> resultData = new HashMap<>();
		
		// Check if the item can be deleted 
		try
		{
			List<Map<String, Object>> checkData;
			
			// 삭제 불가한게 있는지 check						
			if ( grv.getDelete() != null ) {
				for (QueryData deleteData : grv.getDelete()) {
					
					if ( deleteData.getData() != null && !deleteData.getData().isEmpty()) {
						 checkData =  mapper.checkDeleteArea(deleteData.getData());
					
						if ( checkData != null && !checkData.isEmpty() && !"NoData".equals(checkData.get(0).get("area")) ) {
							
							resultData.put("resultCode", "CHECK_DELETE");
							resultData.put("resultData", checkData.get(0).get("area"));
							
							return resultData;
						}	
					}
				}
			}
			
			if ( grv.getInsert() != null ) {
				for (QueryData insertData : grv.getInsert()) {
					
					if ( insertData.getData() != null && !insertData.getData().isEmpty()) {
						 checkData =  mapper.checkInsertArea(insertData.getData());
					
						if ( checkData != null && !checkData.isEmpty() && !"NoData".equals(checkData.get(0).get("area")) ) {
							
							resultData.put("resultCode", "CHECK_INSERT");
							resultData.put("resultData", checkData.get(0).get("area"));
							
							return resultData;
						}	
					}
				}
			}			
			
			if ( resultData.isEmpty() ) {
				// 정상 데이터 변경 저장 처리	
				genericService.saveData(grv);
				resultData.put("resultCode", "SUCCESS");
			}			
		}
		catch ( Exception e ) {
			throw new RuntimeException("saveData error", e);
		}
		
		return resultData;
	}	
	
	public Map<String, Object> saveEquipData(GenericResourceVo grv) {
		
		Map<String, Object> resultData = new HashMap<>();
		
		// Check if the item can be deleted 
		try
		{
			List<Map<String, Object>> checkData;
			
			// 삭제 불가한게 있는지 check			
//			if ( grv.getDelete() != null ) {
//				for (QueryData deleteData : grv.getDelete()) {
//					
//					if ( deleteData.getData() != null && !deleteData.getData().isEmpty()) {
//						 checkData =  mapper.checkDeleteEquip(deleteData.getData());
//					
//						if ( checkData != null && !checkData.isEmpty() && !"NoData".equals(checkData.get(0).get("equip")) ) {
//							
//							resultData.put("resultCode", "CHECK_DELETE");
//							resultData.put("resultData", checkData.get(0).get("equip"));
//							
//							return resultData;
//						}	
//					}
//				}
//			}
			
			if ( grv.getInsert() != null ) {
				for (QueryData insertData : grv.getInsert()) {
					
					if ( insertData.getData() != null && !insertData.getData().isEmpty()) {						
						 checkData =  mapper.checkInsertEquip(insertData.getData());
					
						if ( checkData != null && !checkData.isEmpty() && !"NoData".equals(checkData.get(0).get("equip")) ) {
							
							resultData.put("resultCode", "CHECK_INSERT");
							resultData.put("resultData", checkData.get(0).get("equip"));
							
							return resultData;
						}	
					}
				}
			}					
			
			if ( resultData.isEmpty() ) {
				// 정상 데이터 변경 저장 처리	
				genericService.saveData(grv);
				resultData.put("resultCode", "SUCCESS");
			}			
		}
		catch ( Exception e ) {
			throw new RuntimeException("saveData error", e);
		}
		
		return resultData;
	}		
}
