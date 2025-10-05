/**
*	기준정보 > 일반코드
*/
package com.dowinsys.cost.web.m0006000.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.dowinsys.cost.common.generic.vo.GenericResourceVo;
import com.dowinsys.cost.web.m0006000.service.M0006002Service;

@RestController("com.dowinsys.cost.web.m0006000.controller.M0006002Controller")
@RequestMapping("/api/m0006000/m0006002")
public class M0006002Controller {

	@Autowired
	M0006002Service service;
	
	@PostMapping("/saveData")
	public ResponseEntity<?> saveData(@RequestBody GenericResourceVo grv) {
//		Map<String, Object> resultData = new HashMap<>();
//		resultData = service.saveData(grv);
		return ResponseEntity.ok(service.saveData(grv));		
	}
	
}
