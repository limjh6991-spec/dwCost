/**
 * 타시스템 > 불량반품
 */
package com.dowinsys.cost.web.c0007000.controller;

import com.dowinsys.cost.web.c0007000.service.C0007009Service;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/c0007009")
public class C0007009Controller {

    @Autowired
    private C0007009Service service;

    /** 1) 조회 */
    @GetMapping("/list")
    public List<Map<String, Object>> getRmaList(
            @RequestParam String yyyymm,
            @RequestParam(required = false) String site
    ) {
        Map<String, Object> param = new HashMap<>();
        param.put("yyyymm", yyyymm);
        param.put("site", site);

        return service.getRmaDataList(param);
    }

    /** 2) 추가 */
    @PostMapping("/insert")
    public void insertRma(@RequestBody Map<String, Object> param) {
        // body로 yyyymm, selCode, site, 모델명, rmaIn, rmaOut 받음
        service.insertRmaData(param);
    }

    /** 3) 수정 */
    @PostMapping("/update")
    public void updateRma(@RequestBody Map<String, Object> param) {
        service.updateRmaData(param);
    }

    /** 4) 삭제 */
    @PostMapping("/delete")
    public void deleteRma(@RequestBody Map<String, Object> param) {
        service.deleteRmaData(param);
    }

    /** 5) 팝업 */
    @GetMapping("/popup/model")
    public List<Map<String, Object>> getModelPopup(
            @RequestParam(required = false) String site,
            @RequestParam(required = false) String model
    ) {
        Map<String, Object> param = new HashMap<>();
        param.put("site", site);
        param.put("model", model);
        return service.getModelPopup(param);
    }
}