/**
*	자재관리 > 포장재
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
import com.dowinsys.cost.web.m0001000.mapper.M0001009Mapper;
import com.dowinsys.cost.web.m0001000.service.M0001009Service;

@Service("com.dowinsys.cost.web.m0001000.service.M0001009")
public class M0001009ServiceImpl implements M0001009Service {

	@Autowired
	M0001009Mapper mapper;

	@Autowired
	GenericResourceService genericService;

	@Autowired
	JwtUtil jwUtil;

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
								&& !"NoData".equals(checkData.get(0).get("inNo"))) {

							resultData.put("resultCode", "CHECK_USED");
							resultData.put("resultData", checkData.get(0).get("inNo"));

							return resultData;
						}
					}
				}
			}

			if (grv.getInsert() != null) {
				for (QueryData insertData : grv.getInsert()) {

					if (insertData.getData() != null && !insertData.getData().isEmpty()) {

						LocalTime curTime = LocalTime.now();
						String formatedTime = curTime.format(DateTimeFormatter.ofPattern("HH:mm"));

						for (Map<String, Object> row : insertData.getData()) {
							row.put("inTime", formatedTime);
						}
					}
				}
			}

			if (grv.getUpdate() != null) {
				for (QueryData updateData : grv.getUpdate()) {

					if (updateData.getData() != null && !updateData.getData().isEmpty()) {
						checkData = mapper.checkUseInData(updateData.getData());

						if (checkData != null && !checkData.isEmpty()
								&& !"NoData".equals(checkData.get(0).get("inNo"))) {

							resultData.put("resultCode", "CHECK_USED");
							resultData.put("resultData", checkData.get(0).get("inNo"));

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
			List<CamelMap<String, Object>> checkData;

			if (grv.getDelete() != null) {
				for (QueryData deleteData : grv.getDelete()) {

					if (deleteData.getData() != null && !deleteData.getData().isEmpty()) {
						for (Map<String, Object> data : deleteData.getData()) {
							 							 
							 mapper.updateRemainQtyPlus(data); // 잔량 플러스 처리
							 mapper.deleteOutDetailData(data); // 투입세부내역 삭제
							 mapper.deleteOutData(data); // 투입취소
						}
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
							CamelMap<String, Object> chkData = mapper.selectEtcInfo(data);
							
							if( chkData != null && !chkData.isEmpty() ) {
								
								int remainQty = (int) chkData.get("remainQty");
								int outQty = (int) data.get("outQty");
								
								if ( remainQty < outQty ) {
									TransactionAspectSupport.currentTransactionStatus().setRollbackOnly();
									resultData.put("resultCode", "LACK_QTY");
									resultData.put("resultData", chkData.get("matCategoryName") + "-" + chkData.get("matTypeName"));
									return resultData;
								}
								else {
									data.put("outTime", formatedTime);
									String insertedOutNo = mapper.insertOutData(data); 		// 투입처리
									data.put("outNo", insertedOutNo);
									mapper.insertOutDetailData(data);   // 투입수량 세부
									mapper.updateRemainQtyMinus(data);	// 잔량 마이너스 처리	
								}					
							}							
							else {
								
								TransactionAspectSupport.currentTransactionStatus().setRollbackOnly();
								resultData.put("resultCode", "LACK_QTY");
								resultData.put("resultData", data.get("matCategoryName") + "-" + data.get("matTypeName"));
								return resultData;
							}	
						}
					}
				}
			}

			if (grv.getUpdate() != null) {
				for (QueryData updateData : grv.getUpdate()) {
					if (updateData.getData() != null && !updateData.getData().isEmpty()) {
						for (Map<String, Object> data : updateData.getData()) {
							
							 mapper.updateRemainQtyPlus(data); // 기존 잔량 플러스 처리														 
							 
							//잔량 확인
							CamelMap<String, Object> chkData = mapper.selectEtcInfo(data);
							
							 if( chkData != null && !chkData.isEmpty() ) {
							 	
							 	int remainQty = (int) chkData.get("remainQty");
							 	int outQty = (int) data.get("outQty");
							 	
							 	if ( remainQty < outQty ) {
							 		
							 		TransactionAspectSupport.currentTransactionStatus().setRollbackOnly();							 		
							 		resultData.put("resultCode", "LACK_QTY");
							 		resultData.put("resultData", chkData.get("matCategoryName") + "-" + chkData.get("matTypeName"));
							 		return resultData;
							 	}
							 	else {
							 		mapper.updateOutData(data); 		// 투입처리
							 	    mapper.deleteOutDetailData(data); 	// 기존 투입세부내역 삭제	
							 		mapper.insertOutDetailData(data);   // 투입수량 세부
							 		mapper.updateRemainQtyMinus(data);	// 잔량 마이너스 처리	
							 	}					
							 }							
							 else {
								TransactionAspectSupport.currentTransactionStatus().setRollbackOnly();	
							 	resultData.put("resultCode", "LACK_QTY");
							 	resultData.put("resultData", data.get("matCategoryName") + "-" + data.get("matTypeName"));
							 	return resultData;
							 }	
							 
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
			preStockStatus = mapper.selectPreStockStatus(params);
			
			if ( preStockStatus == null || preStockStatus.isEmpty() ) {
				resultData.put("resultCode", "NOT_EXISTS_PRE");				
			}
			else {
				
				String tempTableName = "temp_sub_mat_etc_stock_" + params.get("stockDate") + "_" + UUID.randomUUID().toString().replace("-", "").substring(0, 8);
				params.put("tempTableName", tempTableName);
				
				mapper.createTempMatStockTable(params);						
			
				mapper.deleteSubMatEtcStock(params);
				mapper.insertSubMatEtcStock(params);
				//mapper.deletetMatCloseInfo(params);
				mapper.insertMatCloseInfo(params);	
				
				mapper.dropTempMatStockTable(params);
	
				resultData.put("resultCode", "SUCCESS");
			}
			
		} catch (Exception e) {
			throw new RuntimeException("saveSummaryData error", e);
		}

		return resultData;
	}
	
	@Transactional
	public Map<String, Object> saveStockData(GenericResourceVo grv) {

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
							mapper.updateSubMatEtcStock(data); 				
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
								mapper.updateSubMatEtcStock(data); 	
							}	
					}
				}
			}
			
			if ( "COMPLETE".equals(grv.getQueryParams().get("status")) || "CLOSE".equals(grv.getQueryParams().get("status"))) {
				
				Integer confirmNCnt = Optional.ofNullable(mapper.selectConfirmN(grv.getQueryParams())).orElse(0);
				
				if ( confirmNCnt != null && ((Number)confirmNCnt).intValue() > 0 ) {
					resultData.put("resultCode", "CHECK_N");
					return resultData;
				}
				
			}
			
			mapper.updatetMatCloseInfo(grv.getQueryParams());

			resultData.put("resultCode", "SUCCESS");
			
		} catch (Exception e) {
			throw new RuntimeException("saveData error", e);
		}

		return resultData;
	}	
	
	@Transactional
	public Map<String, Object> saveMatCategoryData(GenericResourceVo grv) {

		Map<String, Object> resultData = new HashMap<>();

		// Check if the item can be deleted
		try {
			List<Map<String, Object>> checkData;

			if (grv.getDelete() != null) {
				for (QueryData deleteData : grv.getDelete()) {

					if (deleteData.getData() != null && !deleteData.getData().isEmpty()) {
						
						checkData = mapper.checkUsedInMatCategoryData(deleteData.getData());

						if (checkData != null && !checkData.isEmpty()
								&& !"NoData".equals(checkData.get(0).get("matCategory"))) {

							resultData.put("resultCode", "CHECK_USED");
							resultData.put("resultData", checkData.get(0).get("matCategory"));

							return resultData;
						}
					}
				}
			}

			if (grv.getInsert() != null) {
				for (QueryData insertData : grv.getInsert()) {

					if (insertData.getData() != null && !insertData.getData().isEmpty()) {

						checkData = mapper.checkMatCategoryData(insertData.getData());

						if (checkData != null && !checkData.isEmpty()
								&& !"NoData".equals(checkData.get(0).get("matCategory"))) {

							resultData.put("resultCode", "CHECK_DUP");
							resultData.put("resultData", checkData.get(0).get("matCategory"));

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

}
