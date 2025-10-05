/**
*	제조 실적 입력 > Lot Run Card 발행
*/
package com.dowinsys.cost.web.m0003000.mapper;

import java.util.Map;

import org.apache.ibatis.annotations.Mapper;
import org.springframework.stereotype.Repository;
import org.springframework.web.multipart.MultipartFile;

@Repository("com.dowinsys.cost.web.m0003000.mapper.M0003007Mapper")
@Mapper
public interface M0003007Mapper {
	Map<String,Object> getFilmImage(Map<String, String> request);
}
