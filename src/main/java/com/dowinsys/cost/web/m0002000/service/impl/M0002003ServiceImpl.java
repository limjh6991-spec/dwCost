/**
*	프로세스 플래닝 > 제품 모델 관리
*/
package com.dowinsys.cost.web.m0002000.service.impl;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.dowinsys.cost.common.CamelMap;
import com.dowinsys.cost.common.generic.service.GenericResourceService;
import com.dowinsys.cost.common.generic.vo.GenericResourceVo;
import com.dowinsys.cost.common.generic.vo.QueryData;
import com.dowinsys.cost.web.m0002000.mapper.M0002003Mapper;
import com.dowinsys.cost.web.m0002000.service.M0002003Service;

@Service("com.dowinsys.cost.web.m0002000.service.M0002003")
public class M0002003ServiceImpl implements M0002003Service {

	@Autowired
	M0002003Mapper mapper;

	@Autowired
	GenericResourceService genericService;

	public Map<String, Object> saveProdProcData(GenericResourceVo grv) {

		Map<String, Object> resultData = new HashMap<>();

		// Check if the item can be deleted
		try {
			List<Map<String, Object>> checkData;
			
			// 삭제 불가한게 있는지 check
//			if ( grv.getDelete() != null ) {
//				for (QueryData deleteData : grv.getDelete()) {
//					
//					if ( deleteData.getData() != null && !deleteData.getData().isEmpty()) {
//						 checkData =  mapper.checkDeleteProdProc(deleteData.getData());
//					
//						if ( checkData != null && !checkData.isEmpty() && !"NoData".equals(checkData.get(0).get("제품코드")) ) {
//							
//							resultData.put("resultCode", "CHECK_DELETE");
//							resultData.put("resultData", checkData.get(0).get("제품코드"));
//							
//							return resultData;
//						}	
//					}
//				}
//			}
			
			if ( grv.getInsert() != null ) {
				for (QueryData insertData : grv.getInsert()) {
					
					if ( insertData.getData() != null && !insertData.getData().isEmpty()) {
						 checkData =  mapper.checkInsertProdProc(insertData.getData());
					
						if ( checkData != null && !checkData.isEmpty() && !"NoData".equals(checkData.get(0).get("prodProcess")) ) {
							
							resultData.put("resultCode", "CHECK_INSERT");
							resultData.put("resultData", checkData.get(0).get("prodProcess"));
							
							return resultData;
						}	
					}
				}
			}			

			if (resultData.isEmpty()) {
				// 정상 데이터 변경 저장 처리
				genericService.saveData(grv);
				resultData.put("resultCode", "SUCCESS");
			}
		} catch (Exception e) {
			throw new RuntimeException("saveData error", e);
		}

		return resultData;
	}

	public Map<String, Object> saveProcessData(GenericResourceVo grv) {
		
		Map<String, Object> resultData = new HashMap<>();
		
		// Check if the item can be deleted 
		try
		{
			List<Map<String, Object>> checkData;	
			
			// 삭제 불가한게 있는지 check				
			if ( grv.getDelete() != null ) {
				for (QueryData deleteData : grv.getDelete()) {
					
					if ( deleteData.getData() != null && !deleteData.getData().isEmpty()) {
						 checkData =  mapper.checkDeleteProcess(deleteData.getData());
					
						if ( checkData != null && !checkData.isEmpty() && !"NoData".equals(checkData.get(0).get("process")) ) {
							
							resultData.put("resultCode", "CHECK_DELETE");
							resultData.put("resultData", checkData.get(0).get("process"));
							
							return resultData;
						}	
					}
				}
			}
			
			if ( grv.getInsert() != null ) {
				for (QueryData insertData : grv.getInsert()) {
					
					if ( insertData.getData() != null && !insertData.getData().isEmpty()) {
						 checkData =  mapper.checkInsertProcess(insertData.getData());
					
						if ( checkData != null && !checkData.isEmpty() && !"NoData".equals(checkData.get(0).get("process")) ) {
							
							resultData.put("resultCode", "CHECK_INSERT");
							resultData.put("resultData", checkData.get(0).get("process"));
							
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
	
	public Map<String, Object> saveProcessPlanData(GenericResourceVo grv) {
		
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
//						 checkData =  mapper.checkDeleteProcess(deleteData.getData());
//					
//						if ( checkData != null && !checkData.isEmpty() && !"NoData".equals(checkData.get(0).get("processId")) ) {
//							
//							resultData.put("resultCode", "CHECK_DELETE");
//							resultData.put("resultData", checkData.get(0).get("processId"));
//							
//							return resultData;
//						}	
//					}
//				}
//			}
			
			if ( grv.getInsert() != null ) {
				for (QueryData insertData : grv.getInsert()) {
					
					if ( insertData.getData() != null && !insertData.getData().isEmpty()) {
						 checkData =  mapper.checkInsertProcessPlan(insertData.getData());
					
						if ( checkData != null && !checkData.isEmpty() && !"NoData".equals(checkData.get(0).get("processPlan")) ) {
							
							resultData.put("resultCode", "CHECK_INSERT");
							resultData.put("resultData", checkData.get(0).get("processPlan"));
							
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
	
	public Map<String, Object> saveStepData(GenericResourceVo grv) {
		
		Map<String, Object> resultData = new HashMap<>();
		
		// Check if the item can be deleted 
		try
		{
			List<Map<String, Object>> checkData;
			
			// 삭제 불가한게 있는지 check		
			if ( grv.getDelete() != null ) {
				for (QueryData deleteData : grv.getDelete()) {
					
					if ( deleteData.getData() != null && !deleteData.getData().isEmpty()) {
						 checkData =  mapper.checkDeleteStep(deleteData.getData());
					
						if ( checkData != null && !checkData.isEmpty() && !"NoData".equals(checkData.get(0).get("공정코드")) ) {
							
							resultData.put("resultCode", "CHECK_DELETE");
							resultData.put("resultData", checkData.get(0).get("공정코드"));
							
							return resultData;
						}	
					}
				}
			}
			
			if ( grv.getInsert() != null ) {
				for (QueryData insertData : grv.getInsert()) {
					
					if ( insertData.getData() != null && !insertData.getData().isEmpty()) {
						 checkData =  mapper.checkInsertStep(insertData.getData());
					
						if ( checkData != null && !checkData.isEmpty() && !"NoData".equals(checkData.get(0).get("step")) ) {
							
							resultData.put("resultCode", "CHECK_INSERT");
							resultData.put("resultData", checkData.get(0).get("step"));
							
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
