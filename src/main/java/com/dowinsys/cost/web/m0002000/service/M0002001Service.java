/**
*	프로세스 플래닝 > SITE 모델링 관리
*/
package com.dowinsys.cost.web.m0002000.service;

import java.util.List;
import java.util.Map;

import com.dowinsys.cost.common.CamelMap;
import com.dowinsys.cost.common.generic.vo.GenericResourceVo;

public interface M0002001Service {
	
	List<CamelMap<String, Object>> getLineList();
	List<CamelMap<String, Object>> getAreaList();
	List<CamelMap<String, Object>> getEquipList();
	
	Map<String, Object> saveAreaData(GenericResourceVo vo);
	Map<String, Object> saveEquipData(GenericResourceVo vo);


}
