/**
*	제조 실적 조회 > 작업 이력 조회
*/
package com.dowinsys.cost.web.m0005000.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.dowinsys.cost.web.m0005000.service.M0005003Service;

@RestController("com.dowinsys.cost.web.m0005000.controller.M0005003Controller")
@RequestMapping("/api/m0005000/m0005003")
public class M0005003Controller {

	@Autowired
	M0005003Service service;
}
