/**
*	설비관리 > 설비 비가동 관리
*/
package com.dowinsys.cost.web.m0009000.controller;

import java.util.HashMap;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.dowinsys.cost.common.generic.vo.GenericResourceVo;
import com.dowinsys.cost.web.m0009000.service.M0009002Service;

@RestController("com.dowinsys.cost.web.m0009000.controller.M0009002Controller")
@RequestMapping("/api/m0009000/m0009002")
public class M0009002Controller {

	@Autowired
	M0009002Service service;
	
	@PostMapping("/TAB090201/saveData")
	public ResponseEntity<?> saveEquipOffLog(@RequestBody GenericResourceVo grv) {
		return ResponseEntity.ok(service.saveEquipOffLog(grv));
	}		
}
