/**
*	제조 실적 입력 > FRONT
*/
package com.dowinsys.cost.web.m0003000.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.dowinsys.cost.web.m0003000.service.M0003005Service;

@RestController("com.dowinsys.cost.web.m0003000.controller.M0003005Controller")
@RequestMapping("/api/m0003000/m0003005")
public class M0003005Controller {

	@Autowired
	M0003005Service service;
}
