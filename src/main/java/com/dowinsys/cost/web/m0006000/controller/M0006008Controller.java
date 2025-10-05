/**
*	기준정보 > 자동 Stage코드
*/
package com.dowinsys.cost.web.m0006000.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.dowinsys.cost.web.m0006000.service.M0006008Service;

@RestController("com.dowinsys.cost.web.m0006000.controller.M0006008Controller")
@RequestMapping("/api/m0006000/m0006008")
public class M0006008Controller {

	@Autowired
	M0006008Service service;
}
