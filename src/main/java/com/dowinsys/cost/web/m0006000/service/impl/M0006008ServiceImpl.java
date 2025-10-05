/**
*	기준정보 > 자동 Stage코드
*/
package com.dowinsys.cost.web.m0006000.service.impl;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.dowinsys.cost.web.m0006000.mapper.M0006008Mapper;
import com.dowinsys.cost.web.m0006000.service.M0006008Service;

@Service("com.dowinsys.cost.web.m0006000.service.M0006008")
public class M0006008ServiceImpl implements M0006008Service {

	@Autowired
	M0006008Mapper mapper;
}
