/**
*	프로세스 플래닝 > 제품 모델 관리
*/
package com.dowinsys.cost.web.m0002000.controller;

import java.util.HashMap;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.dowinsys.cost.common.generic.vo.GenericResourceVo;
import com.dowinsys.cost.web.m0002000.service.M0002003Service;

@RestController("com.dowinsys.cost.web.m0002000.controller.M0002003Controller")
@RequestMapping("/api/m0002000/m0002003")
public class M0002003Controller {

	@Autowired
	M0002003Service service;
	
	@PostMapping("/saveProdProcData")
	public ResponseEntity<?> saveProdProcData(@RequestBody GenericResourceVo grv) {
		Map<String, Object> resultData = new HashMap<>();
		resultData = service.saveProdProcData(grv);
		return ResponseEntity.ok(resultData);
		
	}
	
	@PostMapping("/saveProcessData")
	public ResponseEntity<?> saveProcessData(@RequestBody GenericResourceVo grv) {
		Map<String, Object> resultData = new HashMap<>();
		resultData = service.saveProcessData(grv);
		return ResponseEntity.ok(resultData);		
	}	
	
	@PostMapping("/saveProcessPlanData")
	public ResponseEntity<?> saveProcessPlanData(@RequestBody GenericResourceVo grv) {
		Map<String, Object> resultData = new HashMap<>();
		resultData = service.saveProcessPlanData(grv);
		return ResponseEntity.ok(resultData);		
	}	
	
	@PostMapping("/saveStepData")
	public ResponseEntity<?> saveStepData(@RequestBody GenericResourceVo grv) {
		Map<String, Object> resultData = new HashMap<>();
		resultData = service.saveStepData(grv);
		return ResponseEntity.ok(resultData);		
	}			
}
