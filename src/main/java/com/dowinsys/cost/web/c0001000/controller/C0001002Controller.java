/**
*	기준정보 > 모델관리
*/
package com.dowinsys.cost.web.c0001000.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.dowinsys.cost.web.c0001000.service.C0001002Service;

@RestController("com.dowinsys.cost.web.c0001000.controller.C0001002Controller")
@RequestMapping("/api/c0001000/c0001002")
public class C0001002Controller {

	@Autowired
	C0001002Service service;
	
}
