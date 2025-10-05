/**
*	공통 코드
*/
package com.dowinsys.cost.common.code.service.impl;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.dowinsys.cost.common.code.mapper.CodeMapper;
import com.dowinsys.cost.common.code.service.CodeService;

@Service("com.dowinsys.cost.common.code.service.CodeService")
public class CodeServiceImpl implements CodeService {

	@Autowired
	CodeMapper mapper;
}
	