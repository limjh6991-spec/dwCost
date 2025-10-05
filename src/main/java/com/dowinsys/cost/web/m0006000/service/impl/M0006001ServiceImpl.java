/**
*	기준정보 > 제품수주서 입력
*/
package com.dowinsys.cost.web.m0006000.service.impl;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.dowinsys.cost.web.m0006000.mapper.M0006001Mapper;
import com.dowinsys.cost.web.m0006000.service.M0006001Service;

@Service("com.dowinsys.cost.web.m0006000.service.M0006001")
public class M0006001ServiceImpl implements M0006001Service {

	@Autowired
	M0006001Mapper mapper;
}
