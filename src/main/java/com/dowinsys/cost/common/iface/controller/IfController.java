/**
 * 타시스템 인터페이스 수신 컨트롤러.
 * 화면 [API 호출] 버튼 → POST /api/iface/fetch → (ERP/MES 호출 + 적재) → 결과 반환.
 * (/api/** 는 SecurityConfig 상 인증 필요)
 */
package com.dowinsys.cost.common.iface.controller;

import com.dowinsys.cost.common.iface.service.IfService;
import com.dowinsys.cost.common.iface.vo.IfFetchRequest;
import com.dowinsys.cost.common.iface.vo.IfFetchResult;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController("com.dowinsys.cost.common.iface.controller.IfController")
@RequestMapping("/api/iface")
public class IfController {

    private static final Logger log = LoggerFactory.getLogger(IfController.class);

    private final IfService service;

    public IfController(IfService service) {
        this.service = service;
    }

    /** 설정/준비 상태 점검 (cert 주입 여부 등). 배포 후 ops 확인용. 비밀값 미노출. */
    @GetMapping("/status")
    public ResponseEntity<Map<String, Object>> status() {
        return ResponseEntity.ok(service.status());
    }

    @PostMapping("/fetch")
    public ResponseEntity<IfFetchResult> fetch(@RequestBody IfFetchRequest req) {
        try {
            return ResponseEntity.ok(service.fetch(req));
        } catch (Exception e) {
            log.error("[IF] fetch 실패 key={}", req == null ? null : req.getKey(), e);
            String key = (req == null) ? null : req.getKey();
            return ResponseEntity.ok(IfFetchResult.error(key, e.getMessage()));
        }
    }
}
