/**
*	기준정보 > 자재 마스터
*/
package com.dowinsys.cost.web.m0006000.service.impl;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.dowinsys.cost.web.m0006000.mapper.M0006004Mapper;
import com.dowinsys.cost.web.m0006000.service.M0006004Service;

@Service("com.dowinsys.cost.web.m0006000.service.M0006004")
public class M0006004ServiceImpl implements M0006004Service {

	@Autowired
	M0006004Mapper mapper;
}
