/**
*	설비관리 > 설비효율 Report
*/
package com.dowinsys.cost.web.m0009000.service.impl;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.interceptor.TransactionAspectSupport;

import com.dowinsys.cost.common.CamelMap;
import com.dowinsys.cost.common.generic.service.GenericResourceService;
import com.dowinsys.cost.common.generic.vo.GenericResourceVo;
import com.dowinsys.cost.common.generic.vo.QueryData;
import com.dowinsys.cost.component.JwtUtil;
import com.dowinsys.cost.web.m0009000.mapper.M0009003Mapper;
import com.dowinsys.cost.web.m0009000.service.M0009003Service;

@Service("com.dowinsys.cost.web.m0009000.service.M0009003")
public class M0009003ServiceImpl implements M0009003Service {

	@Autowired
	M0009003Mapper mapper;

	@Autowired
	GenericResourceService genericService;


}
