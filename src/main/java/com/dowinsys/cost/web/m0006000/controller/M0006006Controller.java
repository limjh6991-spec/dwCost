/**
*	기준정보 > 카세트 정보
*/
package com.dowinsys.cost.web.m0006000.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.dowinsys.cost.web.m0006000.service.M0006006Service;

@RestController("com.dowinsys.cost.web.m0006000.controller.M0006006Controller")
@RequestMapping("/api/m0006000/m0006006")
public class M0006006Controller {

	@Autowired
	M0006006Service service;
}
