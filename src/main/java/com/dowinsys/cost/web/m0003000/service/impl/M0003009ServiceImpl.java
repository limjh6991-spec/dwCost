/**
*	제조 실적 입력 > 포장/출하
*/
package com.dowinsys.cost.web.m0003000.service.impl;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.dowinsys.cost.web.m0003000.mapper.M0003009Mapper;
import com.dowinsys.cost.web.m0003000.service.M0003009Service;

@Service("com.dowinsys.cost.web.m0003000.service.M0003009")
public class M0003009ServiceImpl implements M0003009Service {

	@Autowired
	M0003009Mapper mapper;
}
