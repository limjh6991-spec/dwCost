/**
*	자재관리 > 부자재 - Tool
*/
package com.dowinsys.cost.web.m0001000.service.impl;

import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.interceptor.TransactionAspectSupport;

import com.dowinsys.cost.common.CamelMap;
import com.dowinsys.cost.common.generic.service.GenericResourceService;
import com.dowinsys.cost.common.generic.vo.GenericResourceVo;
import com.dowinsys.cost.common.generic.vo.QueryData;
import com.dowinsys.cost.component.JwtUtil;
import com.dowinsys.cost.web.m0001000.mapper.M0001001Mapper;
import com.dowinsys.cost.web.m0001000.mapper.M0001003Mapper;
import com.dowinsys.cost.web.m0001000.service.M0001003Service;

@Service("com.dowinsys.cost.web.m0001000.service.M0001003")
public class M0001003ServiceImpl implements M0001003Service {

	@Autowired
	M0001003Mapper mapper;
	
	@Autowired
	M0001001Mapper m0001001Mapper;	

	@Autowired
	GenericResourceService genericService;

	@Transactional
	public Map<String, Object> saveInData(GenericResourceVo grv) {

		Map<String, Object> resultData = new HashMap<>();

		// Check if the item can be deleted
		try {
			List<Map<String, Object>> checkData;

			if (grv.getDelete() != null) {
				for (QueryData deleteData : grv.getDelete()) {

					if (deleteData.getData() != null && !deleteData.getData().isEmpty()) {
						checkData = mapper.checkUseInData(deleteData.getData());

						if (checkData != null && !checkData.isEmpty()
								&& !"NoData".equals(checkData.get(0).get("materialId"))) {

							resultData.put("resultCode", "CHECK_USED");
							resultData.put("resultData", checkData.get(0).get("materialId"));

							return resultData;
						}
					}
				}
			}

			if (grv.getInsert() != null) {
				for (QueryData insertData : grv.getInsert()) {

					if (insertData.getData() != null && !insertData.getData().isEmpty()) {
						checkData = mapper.checkInsertInData(insertData.getData());

						if (checkData != null && !checkData.isEmpty()
								&& !"NoData".equals(checkData.get(0).get("materialId"))) {

							resultData.put("resultCode", "CHECK_DUP");
							resultData.put("resultData", checkData.get(0).get("materialId"));

							return resultData;
						} 
						else {
							LocalTime curTime = LocalTime.now();
							String formatedTime = curTime.format(DateTimeFormatter.ofPattern("HH:mm"));
							for (Map<String, Object> row : insertData.getData()) {
								row.put("inTime", formatedTime);
							}
						}
					}
				}
			}
			
			if (grv.getUpdate() != null) {
				for (QueryData updateData : grv.getUpdate()) {

					if (updateData.getData() != null && !updateData.getData().isEmpty()) {
						checkData = mapper.checkUseInData(updateData.getData());

						if (checkData != null && !checkData.isEmpty()
								&& !"NoData".equals(checkData.get(0).get("materialId"))) {

							resultData.put("resultCode", "CHECK_USED");
							resultData.put("resultData", checkData.get(0).get("materialId"));

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

	@Transactional
	public Map<String, Object> saveOutData(GenericResourceVo grv) {

		Map<String, Object> resultData = new HashMap<>();

		// Check if the item can be deleted
		try {
			List<Map<String, Object>> checkData;

			if (grv.getDelete() != null) {
				for (QueryData deleteData : grv.getDelete()) {

					if (deleteData.getData() != null && !deleteData.getData().isEmpty()) {
						
/*						checkData = mapper.checkDeleteInData(deleteData.getData());
						if (checkData != null && !checkData.isEmpty() && !"NoData".equals(checkData.get(0).get("materialId"))) {

							resultData.put("resultCode", "CHECK_DELETE");
							resultData.put("resultData", checkData.get(0).get("materialId"));

							return resultData;
						}
						else {*/
							for (Map<String, Object> data : deleteData.getData()) {
								mapper.deleteOutData(data); 		// 출고취소
								mapper.updateRemainQtyPlus(data); 	// 잔량 플러스 처리
							}							
							
						//}
					}
				}
			}
			
			if (grv.getInsert() != null) {
				for (QueryData insertData : grv.getInsert()) {

					if (insertData.getData() != null && !insertData.getData().isEmpty()) {
						
						LocalTime curTime = LocalTime.now();
						String formatedTime = curTime.format(DateTimeFormatter.ofPattern("HH:mm"));
						
						for (Map<String, Object> data : insertData.getData()) {						    
							
							//잔량 확인
							CamelMap<String, Object> chkData = mapper.checkRemainQty(data);
							//Tool 사용설비 사용구분 확인
							CamelMap<String, Object> chkEquip = mapper.checkEquipTool(data);
							Integer useCount  = (Integer) chkEquip.get("useCount");
							
							if( chkData != null && !chkData.isEmpty() ) {
								TransactionAspectSupport.currentTransactionStatus().setRollbackOnly();								
								resultData.put("resultCode", "LACK_QTY");
								resultData.put("resultData", chkData.get("materialId"));
								return resultData;								
							}
							else if ( chkEquip != null && !chkEquip.isEmpty() && useCount != null && useCount > 0  ) {
							    String 사용구분 = (String) data.get("사용구분");							
							    String equipNm = (String) data.get("equipNm");
								
								TransactionAspectSupport.currentTransactionStatus().setRollbackOnly();
								resultData.put("resultCode", "TOOL_USE");
								resultData.put("resultData", equipNm + " - " + 사용구분 );
								return resultData;	
							}
							else {
								data.put("outTime", formatedTime);
								mapper.insertOutData(data); 		// 투입처리
								mapper.updateRemainQtyMinus(data);	// 잔량 마이너스 처리
							}						
						}
					}
				}
			}		
			

			if (grv.getUpdate() != null) {
				for (QueryData updateData : grv.getUpdate()) {
					if (updateData.getData() != null && !updateData.getData().isEmpty()) {
							for (Map<String, Object> data : updateData.getData()) {
							    
								//Tool 사용설비 사용구분 확인
								if ( !data.get("equipNm").equals(data.get("orgEquipNm"))) {
									
									CamelMap<String, Object> chkEquip = mapper.checkEquipTool(data);
									Integer useCount  = (Integer) chkEquip.get("useCount");
									
									 if ( chkEquip != null && !chkEquip.isEmpty() && useCount != null && useCount > 0  ) {
										    String 사용구분 = (String) data.get("사용구분");							
										    String equipNm = (String) data.get("equipNm");		
										 
											TransactionAspectSupport.currentTransactionStatus().setRollbackOnly();
											resultData.put("resultCode", "TOOL_USE");
											resultData.put("resultData", equipNm + " - " + 사용구분 );
											return resultData;	
									}									
									
								}
								
								mapper.updateOutData(data);
							}	
					}
				}
			}			

			resultData.put("resultCode", "SUCCESS");
			
		} catch (Exception e) {
			throw new RuntimeException("saveData error", e);
		}

		return resultData;
	}
	
	@Transactional
	public Map<String, Object> saveSummaryData(Map<String, Object> params) {

		Map<String, Object> resultData = new HashMap<>();
		String preStockStatus = "";

		try 
		{
			preStockStatus = m0001001Mapper.selectPreStockStatus(params);
			
			if ( preStockStatus == null || preStockStatus.isEmpty() ) {
				resultData.put("resultCode", "NOT_EXISTS_PRE");				
			}
			else { 
				
				String tempTableName = "temp_sub_mat_tool_id_stock_" + params.get("stockDate") + "_" + UUID.randomUUID().toString().replace("-", "").substring(0, 8);
				params.put("tempTableName", tempTableName);
				
				mapper.createTempMatStockTable(params);
			
				mapper.deleteSubMatToolIdStock(params);
				mapper.insertSubMatToolIdStock(params);
				mapper.deleteSubMatToolStock(params);
				mapper.insertSubMatToolStock(params);
				
				m0001001Mapper.insertMatCloseInfo(params);
				
				mapper.dropTempMatStockTable(params);
	
				resultData.put("resultCode", "SUCCESS");
			}
			
		} catch (Exception e) {
			throw new RuntimeException("saveSummaryData error", e);
		}

		return resultData;
	}
	
	@Transactional
	public Map<String, Object> saveStockIdData(GenericResourceVo grv) {

		Map<String, Object> resultData = new HashMap<>();
		
		boolean reSummary = false;

		try {
			List<CamelMap<String, Object>> checkData;
			
			if (grv.getInsert() != null) {
				for (QueryData insertData : grv.getInsert()) {

					if (insertData.getData() != null && !insertData.getData().isEmpty()) {
						
						reSummary = true;						
						for (Map<String, Object> data : insertData.getData()) {
							data.put("workerName", grv.getQueryParams().get("workerName"));
							mapper.updateSubMatToolIdStock(data); 				
						}
					}
				}
			}			

			if (grv.getUpdate() != null) {
				for (QueryData updateData : grv.getUpdate()) {
					if (updateData.getData() != null && !updateData.getData().isEmpty()) {
						
							reSummary = true;
							for (Map<String, Object> data : updateData.getData()) {
								data.put("workerName", grv.getQueryParams().get("workerName"));
								mapper.updateSubMatToolIdStock(data); 	
							}	
					}
				}
			}
			
			if ( reSummary ) {			
				mapper.deleteSubMatToolStock(grv.getQueryParams());
				mapper.insertSubMatToolStock(grv.getQueryParams());
			}
			
			if ( "COMPLETE".equals(grv.getQueryParams().get("status")) || "CLOSE".equals(grv.getQueryParams().get("status"))) {
				
				Integer confirmNCnt = Optional.ofNullable(mapper.selectConfirmN(grv.getQueryParams())).orElse(0);
				
				if ( confirmNCnt != null && ((Number)confirmNCnt).intValue() > 0 ) {
					resultData.put("resultCode", "CHECK_N");
					return resultData;
				}
				
			}
			
			m0001001Mapper.updatetMatCloseInfo(grv.getQueryParams());

			resultData.put("resultCode", "SUCCESS");
			
		} catch (Exception e) {
			throw new RuntimeException("saveData error", e);
		}

		return resultData;
	}			
}
