/**
*	기준정보 > 불량사유 코드
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
import com.dowinsys.cost.web.m0006000.mapper.M0006005Mapper;
import com.dowinsys.cost.web.m0006000.service.M0006005Service;

@Service("com.dowinsys.cost.web.m0006000.service.M0006005")
public class M0006005ServiceImpl implements M0006005Service {

	@Autowired
	M0006005Mapper mapper;
	
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
						 checkData =  mapper.checkInsertDefectCd(insertData.getData());
					
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
