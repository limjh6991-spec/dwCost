/**
*	기준정보 > 모델관리
*/
package com.dowinsys.cost.web.c0001000.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.dowinsys.cost.web.c0001000.service.C0001003Service;

@RestController("com.dowinsys.cost.web.c0001000.controller.C0001003Controller")
@RequestMapping("/api/c0001000/c0001003")
public class C0001003Controller {

	@Autowired
	C0001003Service service;
	
}
