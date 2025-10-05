/**
*	기준정보 > 공정별 불량코드 등록
*/
package com.dowinsys.cost.web.m0006000.controller;

import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.dowinsys.cost.web.m0006000.service.M0006007Service;

@RestController("com.dowinsys.cost.web.m0006000.controller.M0006007Controller")
@RequestMapping("/api/m0006000/m0006007")
public class M0006007Controller {

	@Autowired
	M0006007Service service;
	
	@PostMapping("/saveData")
	public ResponseEntity<?> saveData(@RequestBody Map<String,Object> params) throws Exception {
		return ResponseEntity.ok(service.saveData(params));
	}
}
