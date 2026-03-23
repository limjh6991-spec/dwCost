package com.dowinsys.cost.common.closingmonth.controller;

import com.dowinsys.cost.common.closingmonth.service.CommonService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/common/closing-month")
public class ClosingMonthController {

    @Autowired
    private CommonService commonService;

    @GetMapping("/check")
    public Map<String, Object> checkClosingMonth(@RequestParam("yyyymm") String yyyymm) {
        boolean isClosed = commonService.isClosedMonth(yyyymm);

        Map<String, Object> result = new HashMap<>();
        result.put("yyyymm", yyyymm);
        result.put("isClosed", isClosed);
        return result;
    }
}
