/**
*	기준정보 > 사용자-메뉴 권한 관리
*/
package com.dowinsys.cost.web.c0001000.controller;

import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.dowinsys.cost.web.m0006000.service.M0006009Service;

@RestController("com.dowinsys.cost.web.c0006000.controller.C0006009Controller")
@RequestMapping("/api/c0006000/c0006009")
public class C0001009Controller {

	@Autowired
	M0006009Service service;
	
	@PostMapping("/role/menutab/list")
	public ResponseEntity<?> roleMenuTabList(@RequestBody Map<String, Object> params) {
		return ResponseEntity.ok(service.getRoleMenuTabList(params));
	}	
	
	@PostMapping("/role/menutab/save")
	public ResponseEntity<?> roleMenuTabSave(@RequestBody Map<String, Object> params) {
		service.roleMenuTabSave(params);
		return ResponseEntity.ok("OK");
	}
	
	@PostMapping("/role/user/save")
	public ResponseEntity<?> roleUserSave(@RequestBody Map<String, Object> params) {
		service.roleUserSave(params);
		return ResponseEntity.ok("OK");
	}
	
	@PostMapping("/role/user/delete")
	public ResponseEntity<?> roleUserDelete(@RequestBody Map<String, Object> params) {
		service.roleUserDelete(params);
		return ResponseEntity.ok("OK");
	}
	
	@PostMapping("/role/delete")
	public ResponseEntity<?> roleDelete(@RequestBody Map<String, Object> params) {
		service.roleDelete(params);
		return ResponseEntity.ok("OK");
	}
	
	@PostMapping("/role/save")
	public ResponseEntity<?> roleSave(@RequestBody Map<String, Object> params) {
		return ResponseEntity.ok(service.roleSave(params));
	}
}
