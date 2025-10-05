/**
*	공통 코드
*/
package com.dowinsys.cost.common.code.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.dowinsys.cost.common.code.service.CodeService;

@RestController("com.dowinsys.cost.common.code.controller.CodeController")
@RequestMapping("/api/code")
public class CodeController {

	@Autowired
	CodeService service;
}
