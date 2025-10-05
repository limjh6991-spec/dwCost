/**
*	기준정보 > 거래처 마스터
*/
package com.dowinsys.cost.web.m0006000.service.impl;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.dowinsys.cost.common.generic.service.GenericResourceService;
import com.dowinsys.cost.common.generic.vo.GenericResourceVo;
import com.dowinsys.cost.common.generic.vo.QueryData;
import com.dowinsys.cost.web.m0006000.mapper.M0006003Mapper;
import com.dowinsys.cost.web.m0006000.service.M0006003Service;

@Service("com.dowinsys.cost.web.m0006000.service.M0006003")
public class M0006003ServiceImpl implements M0006003Service {

	@Autowired
	M0006003Mapper mapper;
	
	@Autowired
	GenericResourceService genericService;

	@Override
	public Map<String, Object> saveData(GenericResourceVo grv) {
Map<String, Object> resultData = new HashMap<>();
		
		List<Map<String, Object>> checkData = null;
		
		try {
			if ( grv.getInsert() != null ) {
				for (QueryData insertData : grv.getInsert()) {
					
					if ( insertData.getData() != null && !insertData.getData().isEmpty()) {
						 checkData =  mapper.checkInsertVendorMst(insertData.getData());
					
						if ( checkData != null && !checkData.isEmpty() ) {
							
							resultData.put("resultCode", "CHECK_INSERT");
							resultData.put("resultData", checkData.get(0).get("code"));
							
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
