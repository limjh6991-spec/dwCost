/**
*	제조 실적 조회 > 공정작업 이력 조회
*/
package com.dowinsys.cost.web.m0005000.service.impl;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.dowinsys.cost.web.m0005000.mapper.M0005001Mapper;
import com.dowinsys.cost.web.m0005000.service.M0005001Service;

@Service("com.dowinsys.cost.web.m0005000.service.M0005001")
public class M0005001ServiceImpl implements M0005001Service {

	@Autowired
	M0005001Mapper mapper;
}
