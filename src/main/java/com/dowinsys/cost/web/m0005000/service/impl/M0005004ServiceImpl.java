/**
*	제조 실적 조회 > 재고 폐기처리 조회
*/
package com.dowinsys.cost.web.m0005000.service.impl;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.dowinsys.cost.web.m0005000.mapper.M0005004Mapper;
import com.dowinsys.cost.web.m0005000.service.M0005004Service;

@Service("com.dowinsys.cost.web.m0005000.service.M0005004")
public class M0005004ServiceImpl implements M0005004Service {

	@Autowired
	M0005004Mapper mapper;
}
