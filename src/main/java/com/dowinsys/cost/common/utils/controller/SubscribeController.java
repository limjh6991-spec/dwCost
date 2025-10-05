package com.dowinsys.cost.common.utils.controller;

import java.io.IOException;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import com.dowinsys.cost.web.m0003000.service.M0003005Service;

@RestController
@RequestMapping("/api/subscribe")
public class SubscribeController {

	private final ExecutorService executor = Executors.newCachedThreadPool();
	
	@Autowired
	M0003005Service m0003005Service;
	
	@GetMapping("/wip/calc")
    public SseEmitter wipSubscribe() {
        SseEmitter emitter = new SseEmitter(Long.MAX_VALUE);

        executor.submit(() -> {
            try {
            	emitter.send("집계 시작하였습니다.");
            	m0003005Service.wipCalc();
            	emitter.send("SEND_COMPLETE");
                emitter.complete();
            } catch (IOException e) {
                emitter.completeWithError(e);
            }
        });

        return emitter;
    }
	
	@GetMapping("/dpr/calc")
    public SseEmitter dprSubscribe() {
        SseEmitter emitter = new SseEmitter(Long.MAX_VALUE);

        executor.submit(() -> {
            try {
            	emitter.send("집계 시작하였습니다.");
            	m0003005Service.dprCalc();
            	emitter.send("SEND_COMPLETE");
                emitter.complete();
            } catch (IOException e) {
                emitter.completeWithError(e);
            }
        });

        return emitter;
    }
}
