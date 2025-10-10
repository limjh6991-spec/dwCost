/**
*	기준정보 > 일반코드
*/
package com.dowinsys.cost.web.c0001000.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.dowinsys.cost.common.generic.vo.GenericResourceVo;
import com.dowinsys.cost.web.c0001000.service.C0001007Service;

@RestController("com.dowinsys.cost.web.c0001000.controller.C0001007Controller")
@RequestMapping("/api/c0001000/c0001007")
public class C0001007Controller {

	@Autowired
	C0001007Service service;
	
	@PostMapping("/saveData")
	public ResponseEntity<?> saveData(@RequestBody GenericResourceVo grv) {
//		Map<String, Object> resultData = new HashMap<>();
//		resultData = service.saveData(grv);
		return ResponseEntity.ok(service.saveData(grv));		
	}
	
}
