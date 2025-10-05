/**
*	제조 실적 입력 > 포장/출하
*/
package com.dowinsys.cost.web.m0003000.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.dowinsys.cost.web.m0003000.service.M0003009Service;

@RestController("com.dowinsys.cost.web.m0003000.controller.M0003009Controller")
@RequestMapping("/api/m0003000/m0003009")
public class M0003009Controller {

	@Autowired
	M0003009Service service;
}
