/**
*	제조 실적 관리 > LotNo 변경 관리
*/
package com.dowinsys.cost.web.m0004000.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.dowinsys.cost.web.m0004000.service.M0004002Service;

@RestController("com.dowinsys.cost.web.m0004000.controller.M0004002Controller")
@RequestMapping("/api/m0004000/m0004002")
public class M0004002Controller {

	@Autowired
	M0004002Service service;
}
