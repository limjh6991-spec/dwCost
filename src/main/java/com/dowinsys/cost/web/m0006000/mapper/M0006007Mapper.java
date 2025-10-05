/**
*	기준정보 > 공정별 불량코드 등록
*/
package com.dowinsys.cost.web.m0006000.mapper;

import java.util.Map;

import org.apache.ibatis.annotations.Mapper;
import org.springframework.stereotype.Repository;

@Repository("com.dowinsys.cost.web.m0006000.mapper.M0006007Mapper")
@Mapper
public interface M0006007Mapper {

	int deleteDataAll(Map<String, Object> params);

	int insertDataAll(Map<String, Object> params);

}
