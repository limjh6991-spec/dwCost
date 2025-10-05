/**
*	제조 실적 조회 > 생산 실적 집계
*/
package com.dowinsys.cost.web.m0005000.service.impl;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.dowinsys.cost.web.m0005000.mapper.M0005002Mapper;
import com.dowinsys.cost.web.m0005000.service.M0005002Service;

@Service("com.dowinsys.cost.web.m0005000.service.M0005002")
public class M0005002ServiceImpl implements M0005002Service {

	@Autowired
	M0005002Mapper mapper;
}
