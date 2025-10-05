/**
*	기준정보 > 모델관리
*/
package com.dowinsys.cost.web.m0006000.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.dowinsys.cost.web.m0006000.service.M0006012Service;

@RestController("com.dowinsys.cost.web.m0006000.controller.M0006012Controller")
@RequestMapping("/api/m0006000/m0006012")
public class M0006012Controller {

	@Autowired
	M0006012Service service;
	
}
