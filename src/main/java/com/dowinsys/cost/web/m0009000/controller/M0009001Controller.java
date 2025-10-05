/**
*	설비관리 > 설비 기준정보
*/
package com.dowinsys.cost.web.m0009000.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.dowinsys.cost.common.generic.vo.GenericResourceVo;
import com.dowinsys.cost.web.m0009000.service.M0009001Service;

@RestController("com.dowinsys.cost.web.m0009000.controller.M0009001Controller")
@RequestMapping("/api/m0009000/m0009001")
public class M0009001Controller {

	@Autowired
	M0009001Service service;
	
	@PostMapping("/TAB090101/saveData")
	public ResponseEntity<?> saveEquipProdBase(@RequestBody GenericResourceVo grv) {
		return ResponseEntity.ok(service.saveEquipProdBase(grv));
	}	
	
	@PostMapping("/TAB090102/saveData")
	public ResponseEntity<?> saveEquipOffCode(@RequestBody GenericResourceVo grv) {
		return ResponseEntity.ok(service.saveEquipOffCode(grv));
	}		
}
