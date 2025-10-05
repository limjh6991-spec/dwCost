/**
*	제조 실적 관리 > LotNo 변경 관리
*/
package com.dowinsys.cost.web.m0004000.service.impl;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.dowinsys.cost.web.m0004000.mapper.M0004002Mapper;
import com.dowinsys.cost.web.m0004000.service.M0004002Service;

@Service("com.dowinsys.cost.web.m0004000.service.M0004002")
public class M0004002ServiceImpl implements M0004002Service {

	@Autowired
	M0004002Mapper mapper;
}
