/**
*	자재관리 > 원자재
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
import com.dowinsys.cost.web.m0001000.service.M0001001Service;

@RestController("com.dowinsys.cost.web.m0001000.controller.M0001001Controller")
@RequestMapping("/api/m0001000/m0001001")
public class M0001001Controller {

	@Autowired
	M0001001Service service;
	
	@PostMapping("/TAB001101/getBaseInfo")
	public ResponseEntity<?> getInBaseInfo(@RequestBody Map<String, Object> params) {
		return ResponseEntity.ok(service.getInBaseInfo(params));
	}
	
	@PostMapping("/TAB001101/saveData")
	public ResponseEntity<?> saveInData(@RequestBody GenericResourceVo grv) {
		return ResponseEntity.ok(service.saveInData(grv));
	}
	
	@PostMapping("/TAB001201/getBaseInfo")
	public ResponseEntity<?> getOutBaseInfo(@RequestBody Map<String, Object> params) {
		return ResponseEntity.ok(service.getOutBaseInfo(params));
	}
	
	@PostMapping("/TAB001201/saveData")
	public ResponseEntity<?> saveOutData(@RequestBody GenericResourceVo grv) {
		return ResponseEntity.ok(service.saveOutData(grv));
	}
	
	@PostMapping("/TAB001301/saveSummaryData")
	public ResponseEntity<?> saveSummaryData(@RequestBody Map<String, Object> params) {
		return ResponseEntity.ok(service.saveSummaryData(params));
	}	
	
	@PostMapping("/TAB001301/saveStockIdData")
	public ResponseEntity<?> saveStockIdData(@RequestBody GenericResourceVo grv) {
		return ResponseEntity.ok(service.saveStockIdData(grv));
	}
	
	@PostMapping("/TAB001501/saveData")
	public ResponseEntity<?> saveMstData(@RequestBody GenericResourceVo grv) {
		return ResponseEntity.ok(service.saveMstData(grv));
	}
}
