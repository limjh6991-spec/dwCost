/**
*	제조 실적 조회 > 생산 실적 집계
*/
package com.dowinsys.cost.web.m0005000.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.dowinsys.cost.web.m0005000.service.M0005002Service;

@RestController("com.dowinsys.cost.web.m0005000.controller.M0005002Controller")
@RequestMapping("/api/m0005000/m0005002")
public class M0005002Controller {

	@Autowired
	M0005002Service service;
}
