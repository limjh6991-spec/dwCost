/**
*	프로세스 플래닝 > SITE 모델링 관리
*/
package com.dowinsys.cost.web.m0002000.controller;

import java.util.HashMap;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.dowinsys.cost.common.generic.vo.GenericResourceVo;
import com.dowinsys.cost.web.m0002000.service.M0002001Service;

@RestController("com.dowinsys.cost.web.m0002000.controller.M0002001Controller")
@RequestMapping("/api/m0002000/m0002001")
public class M0002001Controller {

	@Autowired
	M0002001Service service;
	
	@PostMapping("/saveAreaData")
	public ResponseEntity<?> saveAreaData(@RequestBody GenericResourceVo grv) {
		Map<String, Object> resultData = new HashMap<>();
		resultData = service.saveAreaData(grv);
		return ResponseEntity.ok(resultData);		
	}
	
	@PostMapping("/saveEquipData")
	public ResponseEntity<?> saveEquipData(@RequestBody GenericResourceVo grv) {
		Map<String, Object> resultData = new HashMap<>();
		resultData = service.saveEquipData(grv);
		return ResponseEntity.ok(resultData);		
	}			
}
