/**
 * 카세트 관리 > 카세트 세척
 */
package com.dowinsys.cost.web.m0007000.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.dowinsys.cost.web.m0007000.service.M0007003Service;

@RestController("com.dowinsys.cost.web.m0007000.controller.M0007003Controller")
@RequestMapping("/api/m0007000/m0007003")
public class M0007003Controller {

    @Autowired
    M0007003Service service;
}
