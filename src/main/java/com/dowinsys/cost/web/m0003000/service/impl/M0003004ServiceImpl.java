/**
*	제조 실적 입력 > Back#2 Package
*/
package com.dowinsys.cost.web.m0003000.service.impl;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.dowinsys.cost.web.m0003000.mapper.M0003004Mapper;
import com.dowinsys.cost.web.m0003000.service.M0003004Service;

@Service("com.dowinsys.cost.web.m0003000.service.M0003004")
public class M0003004ServiceImpl implements M0003004Service {

	@Autowired
	M0003004Mapper mapper;
}
