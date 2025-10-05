/**
*	제조 실적 관리 > 공정 데이터 수정
*/
package com.dowinsys.cost.web.m0004000.service.impl;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.dowinsys.cost.web.m0004000.mapper.M0004001Mapper;
import com.dowinsys.cost.web.m0004000.service.M0004001Service;

@Service("com.dowinsys.cost.web.m0004000.service.M0004001")
public class M0004001ServiceImpl implements M0004001Service {

	@Autowired
	M0004001Mapper mapper;
}
