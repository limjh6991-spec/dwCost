/**
*	자재관리 > 원자재
*/
package com.dowinsys.cost.web.r0000000.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.dowinsys.cost.web.m0001000.service.M0001001Service;

@RestController("com.dowinsys.cost.web.r0000000.controller.R0000000Controller")
@RequestMapping("/api/r0000000/r0000000")
public class R0000000Controller {

	@Autowired
	M0001001Service service;
}
