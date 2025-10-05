/**
*	제조 실적 입력 > HOLD품 관리
*/
package com.dowinsys.cost.web.m0003000.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.dowinsys.cost.web.m0003000.service.M0003006Service;

@RestController("com.dowinsys.cost.web.m0003000.controller.M0003006Controller")
@RequestMapping("/api/m0003000/m0003006")
public class M0003006Controller {

	@Autowired
	M0003006Service service;
}
