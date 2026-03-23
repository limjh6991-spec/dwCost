package com.dowinsys.cost.common.closingmonth.service.impl;

import com.dowinsys.cost.common.closingmonth.mapper.CommonMapper;
import com.dowinsys.cost.common.closingmonth.service.CommonService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.Map;

@Service
public class CommonServiceImpl implements CommonService {

    @Autowired
    private CommonMapper commonMapper;

    @Override
    public boolean isClosedMonth(String yyyymm) {
        Map<String, Object> param = new HashMap<>();
        param.put("yyyymm", yyyymm);

        int count = commonMapper.isClosedMonth(param);
        return count > 0;
    }
}
