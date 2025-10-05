/**
*	기준정보 > 자재 마스터
*/
package com.dowinsys.cost.web.m0006000.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.dowinsys.cost.web.m0006000.service.M0006004Service;

@RestController("com.dowinsys.cost.web.m0006000.controller.M0006004Controller")
@RequestMapping("/api/m0006000/m0006004")
public class M0006004Controller {

	@Autowired
	M0006004Service service;
}
