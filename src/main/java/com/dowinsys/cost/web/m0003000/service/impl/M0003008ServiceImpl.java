/**
*	제조 실적 입력 > Rework
*/
package com.dowinsys.cost.web.m0003000.service.impl;

import java.util.List;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.dowinsys.cost.web.m0003000.mapper.M0003008Mapper;
import com.dowinsys.cost.web.m0003000.service.M0003008Service;

@Service("com.dowinsys.cost.web.m0003000.service.M0003008")
public class M0003008ServiceImpl implements M0003008Service {

	@Autowired
	M0003008Mapper mapper;

	@Override
	@Transactional
	public void endJob(Map<String, Object> params) {
		mapper.updateEndJobVLR(params);
		
		List<Map<String, Object>> badList = (List<Map<String, Object>>)params.get("badList");
		badList.forEach(badInfo -> mapper.insertReworkBadCnt(badInfo));
		
		List<Map<String, Object>> cstList = (List<Map<String, Object>>)params.get("cstList");
		cstList.forEach(cstInfo -> mapper.insertReworkCst(cstInfo));
	}
	
}
