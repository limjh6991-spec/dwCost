/**
*	제조 실적 입력 > Back#2 Cell QC
*/
package com.dowinsys.cost.web.m0003000.service.impl;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.dowinsys.cost.web.m0003000.mapper.M0003003Mapper;
import com.dowinsys.cost.web.m0003000.service.M0003003Service;

@Service("com.dowinsys.cost.web.m0003000.service.M0003003")
public class M0003003ServiceImpl implements M0003003Service {

	@Autowired
	M0003003Mapper mapper;
}
