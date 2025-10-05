/**
*	제조 실적 조회 > 재고 폐기처리 조회
*/
package com.dowinsys.cost.web.m0005000.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.dowinsys.cost.web.m0005000.service.M0005004Service;

@RestController("com.dowinsys.cost.web.m0005000.controller.M0005004Controller")
@RequestMapping("/api/m0005000/m0005004")
public class M0005004Controller {

	@Autowired
	M0005004Service service;
}
