/**
*	기준정보 > 설비관리
*/
package com.dowinsys.cost.web.m0006000.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.dowinsys.cost.web.m0006000.service.M0006011Service;

@RestController("com.dowinsys.cost.web.m0006000.controller.M0006011Controller")
@RequestMapping("/api/m0006000/m0006011")
public class M0006011Controller {

	@Autowired
	M0006011Service service;
	
}
