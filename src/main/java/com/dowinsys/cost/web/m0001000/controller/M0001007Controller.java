/**
*	자재관리 > 부자재 - 필터
*/
package com.dowinsys.cost.web.m0001000.controller;

import java.util.HashMap;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.dowinsys.cost.common.generic.vo.GenericResourceVo;
import com.dowinsys.cost.web.m0001000.service.M0001007Service;

@RestController("com.dowinsys.cost.web.m0001000.controller.M0001007Controller")
@RequestMapping("/api/m0001000/m0001007")
public class M0001007Controller {

	@Autowired
	M0001007Service service;	
	
	@PostMapping("/TAB001107/saveInData")
	public ResponseEntity<?> saveInData(@RequestBody GenericResourceVo grv) {
		Map<String, Object> resultData = new HashMap<>();
		resultData = service.saveInData(grv);
		return ResponseEntity.ok(resultData);	
	}
	
	@PostMapping("/TAB001207/saveOutData")
	public ResponseEntity<?> saveOutData(@RequestBody GenericResourceVo grv) {
		Map<String, Object> resultData = new HashMap<>();
		resultData = service.saveOutData(grv);
		return ResponseEntity.ok(resultData);	
	}
	
	@PostMapping("/TAB001307/saveSummaryData")
	public ResponseEntity<?> saveSummaryData(@RequestBody Map<String, Object> params) {
		return ResponseEntity.ok(service.saveSummaryData(params));
	}	
	
	@PostMapping("/TAB001307/saveStockData")
	public ResponseEntity<?> saveStockData(@RequestBody GenericResourceVo grv) {
		return ResponseEntity.ok(service.saveStockData(grv));
	}		
}
