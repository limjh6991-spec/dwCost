/**
*	제조 실적 입력 > Back#2 Package
*/
package com.dowinsys.cost.web.m0003000.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.dowinsys.cost.web.m0003000.service.M0003004Service;

@RestController("com.dowinsys.cost.web.m0003000.controller.M0003004Controller")
@RequestMapping("/api/m0003000/m0003004")
public class M0003004Controller {

	@Autowired
	M0003004Service service;
}
