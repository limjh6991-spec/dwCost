/**
*	기준정보 > 일반코드
*/
package com.dowinsys.cost.web.c0001000.service.impl;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.dowinsys.cost.common.CamelMap;
import com.dowinsys.cost.common.generic.service.GenericResourceService;
import com.dowinsys.cost.common.generic.vo.GenericResourceVo;
import com.dowinsys.cost.common.generic.vo.QueryData;
import com.dowinsys.cost.web.c0001000.mapper.C0001007Mapper;
import com.dowinsys.cost.web.c0001000.service.C0001007Service;

@Service("com.dowinsys.cost.web.c0001000.service.C0001007")
public class C0001007ServiceImpl implements C0001007Service {

	@Autowired
	C0001007Mapper mapper;
	
	@Autowired
	GenericResourceService genericService;

	@Override
	public List<CamelMap<String, Object>> getMajCdList() {
		return mapper.getMajCodeList();
	}

	@Override
	public Map<String, Object> saveData(GenericResourceVo grv) {
		Map<String, Object> resultData = new HashMap<>();
		
		List<Map<String, Object>> checkData = null;
		
		try {
			if ( grv.getInsert() != null ) {
				for (QueryData insertData : grv.getInsert()) {
					
					if ( insertData.getData() != null && !insertData.getData().isEmpty()) {
						 checkData =  mapper.checkInsertCommCode(insertData.getData());
					
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
