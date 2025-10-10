/**
*	기준정보 > 모델관리
*/
package com.dowinsys.cost.web.c0001000.service.impl;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.dowinsys.cost.web.c0001000.mapper.C0001001Mapper;
import com.dowinsys.cost.web.c0001000.service.C0001001Service;

@Service("com.dowinsys.cost.web.c0001000.service.C0001001")
public class C0001001ServiceImpl implements C0001001Service {

	@Autowired
	C0001001Mapper mapper;
}
