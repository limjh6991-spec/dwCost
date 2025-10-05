/**
 * 카세트 관리 > 카세트 점검
 */
package com.dowinsys.cost.web.m0007000.service.impl;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.dowinsys.cost.web.m0007000.mapper.M0007002Mapper;
import com.dowinsys.cost.web.m0007000.service.M0007002Service;

@Service("com.dowinsys.cost.web.m0007000.service.M0007002")
public class M0007002ServiceImpl implements M0007002Service {

    @Autowired
    M0007002Mapper mapper;
}
