/**
*	기준정보 > 카세트 정보
*/
package com.dowinsys.cost.web.m0006000.service.impl;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.dowinsys.cost.web.m0006000.mapper.M0006006Mapper;
import com.dowinsys.cost.web.m0006000.service.M0006006Service;

@Service("com.dowinsys.cost.web.m0006000.service.M0006006")
public class M0006006ServiceImpl implements M0006006Service {

	@Autowired
	M0006006Mapper mapper;
}
