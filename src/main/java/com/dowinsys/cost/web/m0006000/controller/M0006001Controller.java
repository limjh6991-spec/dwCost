/**
*	기준정보 > 제품수주서 입력
*/
package com.dowinsys.cost.web.m0006000.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.dowinsys.cost.web.m0006000.service.M0006001Service;

@RestController("com.dowinsys.cost.web.m0006000.controller.M0006001Controller")
@RequestMapping("/api/m0006000/m0006001")
public class M0006001Controller {

	@Autowired
	M0006001Service service;
	
}
