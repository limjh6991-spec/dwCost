/**
*	제조 실적 관리 > HOLD 관리
*/
package com.dowinsys.cost.web.m0004000.service.impl;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.dowinsys.cost.web.m0004000.mapper.M0004003Mapper;
import com.dowinsys.cost.web.m0004000.service.M0004003Service;

@Service("com.dowinsys.cost.web.m0004000.service.M0004003")
public class M0004003ServiceImpl implements M0004003Service {

	@Autowired
	M0004003Mapper mapper;
}
