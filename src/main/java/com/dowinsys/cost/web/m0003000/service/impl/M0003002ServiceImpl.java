/**
*	제조 실적 입력 > Back#2 Cassette QC
*/
package com.dowinsys.cost.web.m0003000.service.impl;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.dowinsys.cost.web.m0003000.mapper.M0003002Mapper;
import com.dowinsys.cost.web.m0003000.service.M0003002Service;

@Service("com.dowinsys.cost.web.m0003000.service.M0003002")
public class M0003002ServiceImpl implements M0003002Service {

	@Autowired
	M0003002Mapper mapper;
}
