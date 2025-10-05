/**
*	설비관리 > 설비 비가동 관리
*/
package com.dowinsys.cost.web.m0009000.service;

import java.util.List;
import java.util.Map;

import com.dowinsys.cost.common.CamelMap;
import com.dowinsys.cost.common.generic.vo.GenericResourceVo;

public interface M0009002Service {
	
	Map<String, Object> saveEquipOffLog(GenericResourceVo grv);
	
}
