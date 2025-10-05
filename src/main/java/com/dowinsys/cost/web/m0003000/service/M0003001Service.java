/**
*	제조 실적 입력 > Back#1
*/
package com.dowinsys.cost.web.m0003000.service;

import java.util.List;
import java.util.Map;

public interface M0003001Service {
	Map<String,Object> search(Map<String, Object> params);
	
	Map<String,Object> searchEquiplog(Map<String, Object> params);

	Map<String,Object> preSearch(Map<String, Object> params);
	
	Map<String, Object> startJob(Map<String, Object> params);
	
	Map<String, Object> reStartJob(Map<String, Object> params);
	
	Map<String, Object> manualAddCst(Map<String, Object> params);
	
	void endJob(Map<String, Object> params);
	
	String saveTemp(Map<String, Object> params);
	
	Map<String, Object> initSave(Map<String, Object> params);
	
	List<Map<String, Object>> reloadCst(Map<String, Object> params);
}
