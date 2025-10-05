/**
*	제조 실적 입력 > Lot Run Card 발행
*/
package com.dowinsys.cost.web.m0003000.service.impl;

import java.io.IOException;
import java.util.HashMap;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import com.dowinsys.cost.common.file.vo.FileVo;
import com.dowinsys.cost.web.m0003000.mapper.M0003007Mapper;
import com.dowinsys.cost.web.m0003000.service.M0003007Service;

@Service("com.dowinsys.cost.web.m0003000.service.M0003007")
public class M0003007ServiceImpl implements M0003007Service {

	@Autowired
	M0003007Mapper mapper;
	
	@Override
	public Map<String,Object> getFilmImage(Map<String, String> request) {
		return mapper.getFilmImage(request);
	}
}
