/**
*	기준정보 > QR정보 등록
*/
package com.dowinsys.cost.web.m0006000.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.dowinsys.cost.web.m0006000.service.M0006013Service;

@RestController("com.dowinsys.cost.web.m0006000.controller.M0006013Controller")
@RequestMapping("/api/m0006000/m0006013")
public class M0006013Controller {

	@Autowired
	M0006013Service service;
	
}
