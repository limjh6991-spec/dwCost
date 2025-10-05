/**
*	제조 실적 입력 > FRONT
*/
package com.dowinsys.cost.web.m0003000.service.impl;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.dowinsys.cost.web.m0003000.mapper.M0003005Mapper;
import com.dowinsys.cost.web.m0003000.service.M0003005Service;

@Service("com.dowinsys.cost.web.m0003000.service.M0003005")
public class M0003005ServiceImpl implements M0003005Service {

	@Autowired
	M0003005Mapper mapper;

	@Override
	public void wipCalc() {
		String calcDate = LocalDate.now().format(DateTimeFormatter.ofPattern("yyyyMMdd"));
		Map<String,Object> params = new HashMap<String,Object>();
    	params.put("calcDate", calcDate);
    	mapper.execCalcWipNow(params);
	}
	
	@Override
	public void dprCalc() {
		String calcDate = LocalDate.now().format(DateTimeFormatter.ofPattern("yyyyMMdd"));
		Map<String,Object> params = new HashMap<String,Object>();
    	params.put("calcDate", calcDate);
    	mapper.execCalcDprNow(params);
	}
}
