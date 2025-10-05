/**
*	프로세스 플래닝 > SITE 모델링 관리
*/
package com.dowinsys.cost.web.m0002000.mapper;

import java.util.List;
import java.util.Map;

import org.apache.ibatis.annotations.Mapper;
import org.springframework.stereotype.Repository;

import com.dowinsys.cost.common.CamelMap;

@Repository("com.dowinsys.cost.web.m0002000.mapper.M0002001Mapper")
@Mapper
public interface M0002001Mapper {
	List<CamelMap<String, Object>> selectLineList();
	List<CamelMap<String, Object>> selectAreaList();
	List<CamelMap<String, Object>> selectEquipList();
	
	List<Map<String, Object>> checkDeleteArea(List<Map<String, Object>> vo);
	List<Map<String, Object>> checkInsertArea(List<Map<String, Object>> vo);
	List<Map<String, Object>> checkInsertEquip(List<Map<String, Object>> vo);
}
