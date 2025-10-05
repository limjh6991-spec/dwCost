/**
 * 카세트 관리 > 카세트 세척
 */
package com.dowinsys.cost.web.m0007000.service.impl;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.dowinsys.cost.web.m0007000.mapper.M0007003Mapper;
import com.dowinsys.cost.web.m0007000.service.M0007003Service;

@Service("com.dowinsys.cost.web.m0007000.service.M0007003")
public class M0007003ServiceImpl implements M0007003Service {

    @Autowired
    M0007003Mapper mapper;
}
