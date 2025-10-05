/**
*	제조 실적 입력 > HOLD품 관리
*/
package com.dowinsys.cost.web.m0003000.service.impl;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.dowinsys.cost.web.m0003000.mapper.M0003006Mapper;
import com.dowinsys.cost.web.m0003000.service.M0003006Service;

@Service("com.dowinsys.cost.web.m0003000.service.M0003006")
public class M0003006ServiceImpl implements M0003006Service {

	@Autowired
	M0003006Mapper mapper;
}
