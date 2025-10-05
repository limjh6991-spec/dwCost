/**
*	설비관리 > 설비 비가동 관리
*/
package com.dowinsys.cost.web.m0009000.service.impl;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.interceptor.TransactionAspectSupport;

import com.dowinsys.cost.common.CamelMap;
import com.dowinsys.cost.common.generic.service.GenericResourceService;
import com.dowinsys.cost.common.generic.vo.GenericResourceVo;
import com.dowinsys.cost.common.generic.vo.QueryData;
import com.dowinsys.cost.component.JwtUtil;
import com.dowinsys.cost.web.m0009000.mapper.M0009002Mapper;
import com.dowinsys.cost.web.m0009000.service.M0009002Service;

@Service("com.dowinsys.cost.web.m0009000.service.M0009002")
public class M0009002ServiceImpl implements M0009002Service {

	@Autowired
	M0009002Mapper mapper;

	@Autowired
	GenericResourceService genericService;

	@Autowired
	JwtUtil jwtUtil;

	@Transactional
	public Map<String, Object> saveEquipOffLog(GenericResourceVo grv) {

		Map<String, Object> resultData = new HashMap<>();

		// Check if the item can be deleted
		try {

			if (grv.getDelete() != null) {
				for (QueryData deleteData : grv.getDelete()) {

					if (deleteData.getData() != null && !deleteData.getData().isEmpty()) {
						for (Map<String, Object> data : deleteData.getData()) {
							 mapper.deleteEquipOffLog(data); 
						}
					}
				}
			}

			if (grv.getInsert() != null) {
				for (QueryData insertData : grv.getInsert()) {

					if (insertData.getData() != null && !insertData.getData().isEmpty()) {

						for (Map<String, Object> data : insertData.getData()) {	
							
							//설비 off date 종료 확인
							List<CamelMap<String, Object>> chkData = mapper.checkEndOffDate(data);

							
							if( chkData != null && !chkData.isEmpty() ) {
								
								TransactionAspectSupport.currentTransactionStatus().setRollbackOnly();
								resultData.put("resultCode", "DUP_ENDDATE");
								resultData.put("resultData", chkData);
								return resultData;				
							}							
							else {
								//설비 off date overlap 확인
								List<CamelMap<String, Object>> chkData2 = mapper.checkDupOffDate(data);	
								
								if( chkData2 != null && !chkData2.isEmpty() ) {
									
									TransactionAspectSupport.currentTransactionStatus().setRollbackOnly();
									resultData.put("resultCode", "DUP_DATE");
									resultData.put("resultData", chkData2);
									return resultData;				
								}
								else { 	
									mapper.insertEquipOffLog(data); 
								}
							}
						}
					}
				}
			}

			if (grv.getUpdate() != null) {
				for (QueryData updateData : grv.getUpdate()) {
					if (updateData.getData() != null && !updateData.getData().isEmpty()) {
						for (Map<String, Object> data : updateData.getData()) {
							
							//설비 off date overlap 확인
							List<CamelMap<String, Object>> chkData = mapper.checkDupOffDateForUpdate(data);	
							
							if( chkData != null && !chkData.isEmpty() ) {
								
								TransactionAspectSupport.currentTransactionStatus().setRollbackOnly();
								resultData.put("resultCode", "DUP_DATE");
								resultData.put("resultData", chkData);
								return resultData;				
							}
							else { 	
								data.put("workerId", jwtUtil.getUserId());								
								mapper.updateEquipOffLog(data); 
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
}
