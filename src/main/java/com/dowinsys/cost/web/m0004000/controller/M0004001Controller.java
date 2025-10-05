/**
*	제조 실적 관리 > 공정 데이터 수정
*/
package com.dowinsys.cost.web.m0004000.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.dowinsys.cost.web.m0004000.service.M0004001Service;

@RestController("com.dowinsys.cost.web.m0004000.controller.M0004001Controller")
@RequestMapping("/api/m0004000/m0004001")
public class M0004001Controller {

	@Autowired
	M0004001Service service;
}
