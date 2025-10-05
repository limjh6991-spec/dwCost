/**
*	기준정보 > QR정보 등록
*/
package com.dowinsys.cost.web.m0006000.service.impl;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.dowinsys.cost.web.m0006000.mapper.M0006013Mapper;
import com.dowinsys.cost.web.m0006000.service.M0006013Service;

@Service("com.dowinsys.cost.web.m0006000.service.M0006013")
public class M0006013ServiceImpl implements M0006013Service {

	@Autowired
	M0006013Mapper mapper;
}
