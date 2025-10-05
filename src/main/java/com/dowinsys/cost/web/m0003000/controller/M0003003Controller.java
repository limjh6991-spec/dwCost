/**
*	제조 실적 입력 > Back#2 Cell QC
*/
package com.dowinsys.cost.web.m0003000.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.dowinsys.cost.web.m0003000.service.M0003003Service;

@RestController("com.dowinsys.cost.web.m0003000.controller.M0003003Controller")
@RequestMapping("/api/m0003000/m0003003")
public class M0003003Controller {

	@Autowired
	M0003003Service service;
}
