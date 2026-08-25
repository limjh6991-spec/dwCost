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
    public boolean isClosedMonth(String yyyymm, String site) {
        Map<String, Object> param = new HashMap<>();
        param.put("yyyymm", yyyymm);
        param.put("site", site);   // HQ/VN 사업장별 마감 판정 (null이면 사업장 무관)

        int count = commonMapper.isClosedMonth(param);
        return count > 0;
    }
}
