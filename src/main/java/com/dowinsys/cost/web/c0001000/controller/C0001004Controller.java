/**
*  기준정보 > 사용자-메뉴 권한 관리
*/
package com.dowinsys.cost.web.c0001000.controller;

import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.dowinsys.cost.web.c0001000.service.C0001004Service;


@RestController("com.dowinsys.cost.web.c0001000.controller.C0001004Controller")
@RequestMapping("/api/c0001000/c0001004")
public class C0001004Controller {

	@Autowired
	C0001004Service service;

	// Tab1
	@PostMapping("/tab1/select")
	public ResponseEntity<?> selectTab1GridData(@RequestBody Map<String, Object> params) {
		return ResponseEntity.ok(service.selectTab1GridData(params));
	}
	@PostMapping("/tab1/insert")
	public ResponseEntity<?> insertTab1Data(@RequestBody Map<String, Object> body) {
		return ResponseEntity.ok(service.insertTab1Data(body));
	}
	@PostMapping("/tab1/update")
	public ResponseEntity<?> updateTab1Data(@RequestBody Map<String, Object> body) {
		return ResponseEntity.ok(service.updateTab1Data(body));
	}
	@PostMapping("/tab1/delete")
	public ResponseEntity<?> deleteTab1Data(@RequestBody Map<String, Object> body) {
		return ResponseEntity.ok(service.deleteTab1Data(body));
	}

	// Tab2
	@PostMapping("/tab2/select")
	public ResponseEntity<?> selectTab2GridData(@RequestBody Map<String, Object> params) {
		return ResponseEntity.ok(service.selectTab2GridData(params));
	}
	@PostMapping("/tab2/insert")
	public ResponseEntity<?> insertTab2Data(@RequestBody Map<String, Object> body) {
		return ResponseEntity.ok(service.insertTab2Data(body));
	}
	@PostMapping("/tab2/update")
	public ResponseEntity<?> updateTab2Data(@RequestBody Map<String, Object> body) {
		return ResponseEntity.ok(service.updateTab2Data(body));
	}
	@PostMapping("/tab2/delete")
	public ResponseEntity<?> deleteTab2Data(@RequestBody Map<String, Object> body) {
		return ResponseEntity.ok(service.deleteTab2Data(body));
	}

	// Tab3
	@PostMapping("/tab3/select")
	public ResponseEntity<?> selectTab3GridData(@RequestBody Map<String, Object> params) {
		return ResponseEntity.ok(service.selectTab3GridData(params));
	}
	@PostMapping("/tab3/insert")
	public ResponseEntity<?> insertTab3Data(@RequestBody Map<String, Object> body) {
		return ResponseEntity.ok(service.insertTab3Data(body));
	}
	@PostMapping("/tab3/update")
	public ResponseEntity<?> updateTab3Data(@RequestBody Map<String, Object> body) {
		return ResponseEntity.ok(service.updateTab3Data(body));
	}
	@PostMapping("/tab3/delete")
	public ResponseEntity<?> deleteTab3Data(@RequestBody Map<String, Object> body) {
		return ResponseEntity.ok(service.deleteTab3Data(body));
    }
    // Tab5
	@PostMapping("/tab5/select")
	public ResponseEntity<?> selectTab5GridData(@RequestBody Map<String, Object> params) {
		return ResponseEntity.ok(service.selectTab5GridData(params));
	}
	@PostMapping("/tab5/insert")
	public ResponseEntity<?> insertTab5Data(@RequestBody Map<String, Object> body) {
		return ResponseEntity.ok(service.insertTab5Data(body));
	}
	@PostMapping("/tab5/update")
	public ResponseEntity<?> updateTab5Data(@RequestBody Map<String, Object> body) {
		return ResponseEntity.ok(service.updateTab5Data(body));
	}
	@PostMapping("/tab5/delete")
	public ResponseEntity<?> deleteTab5Data(@RequestBody Map<String, Object> body) {
		return ResponseEntity.ok(service.deleteTab5Data(body));
	}
}
