/**
*  기준정보 > 사용자-메뉴 권한 관리
*/
package com.dowinsys.cost.web.c0001000.mapper;

import java.util.List;
import java.util.Map;
import com.dowinsys.cost.common.CamelMap;

import org.apache.ibatis.annotations.Mapper;
import org.springframework.stereotype.Repository;

import com.dowinsys.cost.common.auth.SysResource;

@Repository("com.dowinsys.cost.web.c0001000.mapper.C0001004Mapper")
@Mapper
public interface C0001004Mapper {
	// Tab1
	List<CamelMap<String, Object>> selectTab1GridData(Map<String, Object> params);
	int insertTab1Data(Map<String, Object> body);
	int updateTab1Data(Map<String, Object> body);
	int deleteTab1Data(Map<String, Object> body);

	// Tab2
	List<CamelMap<String, Object>> selectTab2GridData(Map<String, Object> params);
	int insertTab2Data(Map<String, Object> body);
	int updateTab2Data(Map<String, Object> body);
	int deleteTab2Data(Map<String, Object> body);

	// Tab3
	List<CamelMap<String, Object>> selectTab3GridData(Map<String, Object> params);
	int insertTab3Data(Map<String, Object> body);
	int updateTab3Data(Map<String, Object> body);
	int deleteTab3Data(Map<String, Object> body);

	// Tab5
	List<CamelMap<String, Object>> selectTab5GridData(Map<String, Object> params);
	int insertTab5Data(Map<String, Object> body);
	int updateTab5Data(Map<String, Object> body);
	int deleteTab5Data(Map<String, Object> body);
}
