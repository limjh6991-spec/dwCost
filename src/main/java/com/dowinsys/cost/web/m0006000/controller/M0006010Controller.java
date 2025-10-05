/**
*	기준정보 > 제품개발이력 관리
*/
package com.dowinsys.cost.web.m0006000.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.dowinsys.cost.web.m0006000.service.M0006010Service;

@RestController("com.dowinsys.cost.web.m0006000.controller.M0006010Controller")
@RequestMapping("/api/m0006000/m0006010")
public class M0006010Controller {

	@Autowired
	M0006010Service service;
	
}
