/**
*	자재관리 > 포장재
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
import com.dowinsys.cost.web.m0001000.service.M0001009Service;

@RestController("com.dowinsys.cost.web.m0001000.controller.M0001009Controller")
@RequestMapping("/api/m0001000/m0001009")
public class M0001009Controller {

	@Autowired
	M0001009Service service;	
	
	@PostMapping("/TAB001109/saveInData")
	public ResponseEntity<?> saveInData(@RequestBody GenericResourceVo grv) {
		Map<String, Object> resultData = new HashMap<>();
		resultData = service.saveInData(grv);
		return ResponseEntity.ok(resultData);	
	}
	
	@PostMapping("/TAB001209/saveOutData")
	public ResponseEntity<?> saveOutData(@RequestBody GenericResourceVo grv) {
		Map<String, Object> resultData = new HashMap<>();
		resultData = service.saveOutData(grv);
		return ResponseEntity.ok(resultData);	
	}
	
	@PostMapping("/TAB001309/saveSummaryData")
	public ResponseEntity<?> saveSummaryData(@RequestBody Map<String, Object> params) {
		return ResponseEntity.ok(service.saveSummaryData(params));
	}	
	
	@PostMapping("/TAB001309/saveStockData")
	public ResponseEntity<?> saveStockData(@RequestBody GenericResourceVo grv) {
		return ResponseEntity.ok(service.saveStockData(grv));
	}	
	
	@PostMapping("/TAB001509/saveMatCategoryData")
	public ResponseEntity<?> saveMatCategoryData(@RequestBody GenericResourceVo grv) {
		return ResponseEntity.ok(service.saveMatCategoryData(grv));
	}
}
