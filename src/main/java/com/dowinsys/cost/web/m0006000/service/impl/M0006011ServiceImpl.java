/**
*	기준정보 > 설비관리
*/
package com.dowinsys.cost.web.m0006000.service.impl;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.dowinsys.cost.web.m0006000.mapper.M0006011Mapper;
import com.dowinsys.cost.web.m0006000.service.M0006011Service;

@Service("com.dowinsys.cost.web.m0006000.service.M0006011")
public class M0006011ServiceImpl implements M0006011Service {

	@Autowired
	M0006011Mapper mapper;
}
