/**
*	제조 실적 입력 > Rework
*/
package com.dowinsys.cost.web.m0003000.controller;

import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.dowinsys.cost.web.m0003000.service.M0003008Service;

@RestController("com.dowinsys.cost.web.m0003000.controller.M0003008Controller")
@RequestMapping("/api/m0003000/m0003008")
public class M0003008Controller {

	@Autowired
	M0003008Service service;
	
	@PostMapping("/endjob")
	public ResponseEntity<?> endJob(@RequestBody Map<String, Object> params){
		service.endJob(params);
		return ResponseEntity.ok("ok");
	}
}
