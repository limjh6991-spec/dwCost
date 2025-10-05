/**
*	기준정보 > 제품개발이력 관리
*/
package com.dowinsys.cost.web.m0006000.service.impl;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.dowinsys.cost.web.m0006000.mapper.M0006010Mapper;
import com.dowinsys.cost.web.m0006000.service.M0006010Service;

@Service("com.dowinsys.cost.web.m0006000.service.M0006010")
public class M0006010ServiceImpl implements M0006010Service {

	@Autowired
	M0006010Mapper mapper;
}
