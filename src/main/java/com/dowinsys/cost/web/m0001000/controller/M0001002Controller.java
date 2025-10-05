/**
*	자재관리 > 부자재-레진
*/
package com.dowinsys.cost.web.m0001000.controller;

import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.dowinsys.cost.common.generic.vo.GenericResourceVo;
import com.dowinsys.cost.web.m0001000.service.M0001002Service;

@RestController("com.dowinsys.cost.web.m0001000.controller.M0001002Controller")
@RequestMapping("/api/m0001000/m0001002")
public class M0001002Controller {

	@Autowired
	M0001002Service service;
	
	@PostMapping("/TAB001102/getBaseInfo")
	public ResponseEntity<?> getInBaseInfo(@RequestBody Map<String, Object> params) {
		return ResponseEntity.ok(service.getInBaseInfo(params));
	}
	
	@PostMapping("/TAB001102/saveData")
	public ResponseEntity<?> saveInData(@RequestBody GenericResourceVo grv) {
		return ResponseEntity.ok(service.saveInData(grv));
	}
	
	@PostMapping("/TAB001202/saveData")
	public ResponseEntity<?> saveOutData(@RequestBody GenericResourceVo grv) {
		return ResponseEntity.ok(service.saveOutData(grv));
	}
	
	@PostMapping("/TAB001302/saveSummaryData")
	public ResponseEntity<?> saveSummaryData(@RequestBody Map<String, Object> params) {
		return ResponseEntity.ok(service.saveSummaryData(params));
	}	
	
	@PostMapping("/TAB001302/saveStockIdData")
	public ResponseEntity<?> saveStockIdData(@RequestBody GenericResourceVo grv) {
		return ResponseEntity.ok(service.saveStockIdData(grv));
	}
		
}
