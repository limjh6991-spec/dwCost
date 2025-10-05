/**
*	기준정보 > 모델관리
*/
package com.dowinsys.cost.web.m0006000.service.impl;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.dowinsys.cost.web.m0006000.mapper.M0006012Mapper;
import com.dowinsys.cost.web.m0006000.service.M0006012Service;

@Service("com.dowinsys.cost.web.m0006000.service.M0006012")
public class M0006012ServiceImpl implements M0006012Service {

	@Autowired
	M0006012Mapper mapper;
}
