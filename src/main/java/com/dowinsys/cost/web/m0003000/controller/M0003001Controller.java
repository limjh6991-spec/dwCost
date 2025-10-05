/**
*	제조 실적 입력 > Back#1
*/
package com.dowinsys.cost.web.m0003000.controller;

import java.util.List;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.dowinsys.cost.web.m0003000.service.M0003001Service;

@RestController("com.dowinsys.cost.web.m0003000.controller.M0003001Controller")
@RequestMapping("/api/m0003000/m0003001")
public class M0003001Controller {

	@Autowired
	M0003001Service service;
	
	@PostMapping("/presearch")
	public ResponseEntity<Map<String, Object>> preSearch(@RequestBody Map<String, Object> params){
		return ResponseEntity.ok(service.preSearch(params));
	}
	
	@PostMapping("/search")
	public ResponseEntity<Map<String, Object>> search(@RequestBody Map<String, Object> params){
		return ResponseEntity.ok(service.search(params));
	}
	
	@PostMapping("/search/equiplog")
	public ResponseEntity<Map<String, Object>> searchEquiplog(@RequestBody Map<String, Object> params){
		return ResponseEntity.ok(service.searchEquiplog(params));
	}
	
	@PostMapping("/startjob")
	public ResponseEntity<?> startJob(@RequestBody Map<String, Object> params){
		Map<String, Object> reulst = service.startJob(params);
		return ResponseEntity.ok(reulst);
	}
	
	@PostMapping("/restartjob")
	public ResponseEntity<?> reStartJob(@RequestBody Map<String, Object> params){
		Map<String, Object> reulst = service.reStartJob(params);
		return ResponseEntity.ok(reulst);
	}
	
	@PostMapping("/manualaddcst")
	public ResponseEntity<?> manualAddCst(@RequestBody Map<String, Object> params){
		Map<String, Object> reulst = service.manualAddCst(params);
		return ResponseEntity.ok(reulst);
	}
	
	@PostMapping("/endjob")
	public ResponseEntity<?> endJob(@RequestBody Map<String, Object> params){
		service.endJob(params);
		return ResponseEntity.ok("ok");
	}
	
	@PostMapping("/savetemp")
	public ResponseEntity<?> saveTemp(@RequestBody Map<String, Object> params){
		return ResponseEntity.ok(service.saveTemp(params));
	}
	
	@PostMapping("/initsave")
	public ResponseEntity<?> initSave(@RequestBody Map<String, Object> params){
		return ResponseEntity.ok(service.initSave(params));
	}
	
	@PostMapping("/reload/cst")
	public ResponseEntity<List<Map<String, Object>>> reloadCst(@RequestBody Map<String, Object> params){
		return ResponseEntity.ok(service.reloadCst(params));
	}
}
