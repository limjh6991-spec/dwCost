/**
*	설비관리 > 설비 기준정보
*/
package com.dowinsys.cost.web.m0009000.service.impl;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.dowinsys.cost.common.CamelMap;
import com.dowinsys.cost.common.generic.service.GenericResourceService;
import com.dowinsys.cost.common.generic.vo.GenericResourceVo;
import com.dowinsys.cost.common.generic.vo.QueryData;
import com.dowinsys.cost.component.JwtUtil;
import com.dowinsys.cost.web.m0009000.mapper.M0009001Mapper;
import com.dowinsys.cost.web.m0009000.service.M0009001Service;

@Service("com.dowinsys.cost.web.m0009000.service.M0009001")
public class M0009001ServiceImpl implements M0009001Service {

	@Autowired
	M0009001Mapper mapper;

	@Autowired
	GenericResourceService genericService;

	@Autowired
	JwtUtil jwtUtil;

	@Transactional
	public Map<String, Object> saveEquipProdBase(GenericResourceVo grv) {

		Map<String, Object> resultData = new HashMap<>();

		// Check if the item can be deleted
		try {
			
			List<CamelMap<String, Object>> checkData;
			
			if (grv.getInsert() != null) {
				for (QueryData insertData : grv.getInsert()) {

					if (insertData.getData() != null && !insertData.getData().isEmpty()) {

						checkData = mapper.checkApplyDate(insertData.getData());

						if (checkData != null && !checkData.isEmpty()) {

							resultData.put("resultCode", "CHECK_DATE");
							resultData.put("resultData", checkData);

							return resultData;
						}
					}
				}
			}

			if (grv.getUpdate() != null) {
				for (QueryData updateData : grv.getUpdate()) {

					if (updateData.getData() != null && !updateData.getData().isEmpty()) {

						String userId = jwtUtil.getUserId();

						for (Map<String, Object> row : updateData.getData()) {
							row.put("workerId", userId);
							
							/*
							 * checkData = mapper.checkApplyDateForUpdate(row);
							 * 
							 * if (checkData != null && !checkData.isEmpty()) {
							 * 
							 * resultData.put("resultCode", "CHECK_DATE"); resultData.put("resultData",
							 * checkData);
							 * 
							 * return resultData; }
							 */						
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
	public Map<String, Object> saveEquipOffCode(GenericResourceVo grv) {

		Map<String, Object> resultData = new HashMap<>();

		// Check if the item can be deleted
		try {
			List<CamelMap<String, Object>> checkData;
			
			if (grv.getDelete() != null) {
				for (QueryData deleteData : grv.getDelete()) {

					if (deleteData.getData() != null && !deleteData.getData().isEmpty()) {
						
						checkData = mapper.checkUsedOffCode(deleteData.getData());

						if (checkData != null && !checkData.isEmpty()
								&& !"NoData".equals(checkData.get(0).get("offCode"))) {

							resultData.put("resultCode", "CHECK_USED");
							resultData.put("resultData", checkData.get(0).get("offCode"));

							return resultData;
						}
					}
				}
			}			
			
			if (grv.getInsert() != null) {
				for (QueryData insertData : grv.getInsert()) {

					if (insertData.getData() != null && !insertData.getData().isEmpty()) {
						
						checkData = mapper.checkExistsOffCode(insertData.getData());

						if (checkData != null && !checkData.isEmpty()
								&& !"NoData".equals(checkData.get(0).get("offCode"))) {

							resultData.put("resultCode", "CHECK_DUP");
							resultData.put("resultData", checkData);

							return resultData;
						}
					}
				}
			}

			if (grv.getUpdate() != null) {
				for (QueryData updateData : grv.getUpdate()) {

					if (updateData.getData() != null && !updateData.getData().isEmpty()) {

						String userId = jwtUtil.getUserId();

						for (Map<String, Object> row : updateData.getData()) {
							row.put("workerId", userId);
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
