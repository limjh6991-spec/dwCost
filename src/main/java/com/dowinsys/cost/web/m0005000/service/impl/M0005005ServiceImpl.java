/**
*	제조 실적 조회 > 재공, 재고 이력 조회
*/
package com.dowinsys.cost.web.m0005000.service.impl;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.dowinsys.cost.web.m0005000.mapper.M0005005Mapper;
import com.dowinsys.cost.web.m0005000.service.M0005005Service;

@Service("com.dowinsys.cost.web.m0005000.service.M0005005")
public class M0005005ServiceImpl implements M0005005Service {

	@Autowired
	M0005005Mapper mapper;
}
