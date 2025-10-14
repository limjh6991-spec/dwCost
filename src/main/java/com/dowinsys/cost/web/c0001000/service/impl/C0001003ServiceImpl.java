/**
*	기준정보 > 모델관리
*/
package com.dowinsys.cost.web.c0001000.service.impl;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.dowinsys.cost.web.c0001000.mapper.C0001003Mapper;
import com.dowinsys.cost.web.c0001000.service.C0001003Service;

@Service("com.dowinsys.cost.web.c0001000.service.C0001003")
public class C0001003ServiceImpl implements C0001003Service {

	@Autowired
	C0001003Mapper mapper;
}
