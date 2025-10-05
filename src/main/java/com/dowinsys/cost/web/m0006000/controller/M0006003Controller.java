/**
*	기준정보 > 거래처 마스터
*/
package com.dowinsys.cost.web.m0006000.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.dowinsys.cost.common.generic.vo.GenericResourceVo;
import com.dowinsys.cost.web.m0006000.service.M0006003Service;

@RestController("com.dowinsys.cost.web.m0006000.controller.M0006003Controller")
@RequestMapping("/api/m0006000/m0006003")
public class M0006003Controller {

	@Autowired
	M0006003Service service;
	
	@PostMapping("/saveData")
	public ResponseEntity<?> saveData(@RequestBody GenericResourceVo grv) {
		return ResponseEntity.ok(service.saveData(grv));		
	}
}
