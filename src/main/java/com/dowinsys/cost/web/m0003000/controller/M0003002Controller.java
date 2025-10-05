/**
*	제조 실적 입력 > Back#2 Cassette QC
*/
package com.dowinsys.cost.web.m0003000.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.dowinsys.cost.web.m0003000.service.M0003002Service;

@RestController("com.dowinsys.cost.web.m0003000.controller.M0003002Controller")
@RequestMapping("/api/m0003000/m0003002")
public class M0003002Controller {

	@Autowired
	M0003002Service service;
}
