/**
*	제조 실적 조회 > 작업 이력 조회
*/
package com.dowinsys.cost.web.m0005000.service.impl;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.dowinsys.cost.web.m0005000.mapper.M0005003Mapper;
import com.dowinsys.cost.web.m0005000.service.M0005003Service;

@Service("com.dowinsys.cost.web.m0005000.service.M0005003")
public class M0005003ServiceImpl implements M0005003Service {

	@Autowired
	M0005003Mapper mapper;
}
