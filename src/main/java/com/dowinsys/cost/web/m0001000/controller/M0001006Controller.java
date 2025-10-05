/**
*	자재관리 > 부자재 - 약액
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
import com.dowinsys.cost.web.m0001000.service.M0001006Service;

@RestController("com.dowinsys.cost.web.m0001000.controller.M0001006Controller")
@RequestMapping("/api/m0001000/m0001006")
public class M0001006Controller {

	@Autowired
	M0001006Service service;
	
	@PostMapping("/TAB001106/saveInData")
	public ResponseEntity<?> saveInData(@RequestBody GenericResourceVo grv) {
		Map<String, Object> resultData = new HashMap<>();
		resultData = service.saveInData(grv);
		return ResponseEntity.ok(resultData);	
	}
	
	@PostMapping("/TAB001206/saveOutData")
	public ResponseEntity<?> saveOutData(@RequestBody GenericResourceVo grv) {
		Map<String, Object> resultData = new HashMap<>();
		resultData = service.saveOutData(grv);
		return ResponseEntity.ok(resultData);	
	}
	
	@PostMapping("/TAB001506/saveReturnData")
	public ResponseEntity<?> saveReturnData(@RequestBody GenericResourceVo grv) {
		Map<String, Object> resultData = new HashMap<>();
		resultData = service.saveReturnData(grv);
		return ResponseEntity.ok(resultData);	
	}
	
	@PostMapping("/TAB001306/saveSummaryData")
	public ResponseEntity<?> saveSummaryData(@RequestBody Map<String, Object> params) {
		return ResponseEntity.ok(service.saveSummaryData(params));
	}	
	
	@PostMapping("/TAB001306/saveStockIdData")
	public ResponseEntity<?> saveStockIdData(@RequestBody GenericResourceVo grv) {
		return ResponseEntity.ok(service.saveStockIdData(grv));
	}	
}
