package com.dowinsys.cost.common.batch.service;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import com.dowinsys.cost.common.batch.mapper.BatchSchedulerMapper;

@Component
public class BatchScheduler {
	
	@Value("${batch.scheduler.enabled}")
    private boolean batchSchedulerEnabled;
	
	@Autowired
	BatchSchedulerMapper batchSchedulerMapper;
	
	@Scheduled(cron = "0 0,15,30,45 * * * *")
    public void wipCalcBatchJob() {
        System.out.println("재공/제고 집계 배치 작업 시작 실행: " + java.time.LocalDateTime.now());
        System.out.println("batchSchedulerEnabled: " + batchSchedulerEnabled);
        
        String calcDate = LocalDate.now().format(DateTimeFormatter.ofPattern("yyyyMMdd"));
        long startTime = System.nanoTime(); // 시작 시간
        
        if(batchSchedulerEnabled) {
        	Map<String,Object> params = new HashMap<String,Object>();
        	params.put("calcDate", calcDate);
        	batchSchedulerMapper.execCalcWip(params);
        }
        
        long endTime = System.nanoTime(); // 종료 시간
        long duration = (endTime - startTime) / 1_000_000_000; // 나노초 -> 초 변환
        
        System.out.println("재공/제고 집계 배치 작업 완료 (" + duration + "초 소요)");
    }
	
	@Scheduled(cron = "0 10 08 * * *")
    public void processDailyErrorReportBatchJob() {
        System.out.println("일별 공정별 불량현황 배치 작업 시작 실행: " + java.time.LocalDateTime.now());
        System.out.println("batchSchedulerEnabled: " + batchSchedulerEnabled);
        
        String calcDate = LocalDate.now().minusDays(1).format(DateTimeFormatter.ofPattern("yyyyMMdd"));
        long startTime = System.nanoTime(); // 시작 시간
        
        if(batchSchedulerEnabled) {
        	System.out.println("일별 공정별 불량현황 배치 실행 일자 (" + calcDate + ")");
        	Map<String,Object> params = new HashMap<String,Object>();
        	params.put("calcDate", calcDate);
        	batchSchedulerMapper.execCreatedFrontData(params);
        	batchSchedulerMapper.execCreatedBackData(params);
        }
        
        long endTime = System.nanoTime(); // 종료 시간
        long duration = (endTime - startTime) / 1_000_000_000; // 나노초 -> 초 변환
        
        System.out.println("일별 공정별 불량현황 배치 작업 완료 (" + duration + "초 소요)");
    }
	
	@Scheduled(cron = "0 15 08 * * *")
    public void dprCalcBatchJob() {
        System.out.println("생산일보 집계 배치 작업 시작 실행: " + java.time.LocalDateTime.now());
        System.out.println("batchSchedulerEnabled: " + batchSchedulerEnabled);
        
        String calcDate = LocalDate.now().minusDays(1).format(DateTimeFormatter.ofPattern("yyyyMMdd"));
        long startTime = System.nanoTime(); // 시작 시간
        
        if(batchSchedulerEnabled) {
        	Map<String,Object> params = new HashMap<String,Object>();
        	params.put("calcDate", calcDate);
        	batchSchedulerMapper.execCalcDpr(params);
        }
        
        long endTime = System.nanoTime(); // 종료 시간
        long duration = (endTime - startTime) / 1_000_000_000; // 나노초 -> 초 변환
        
        System.out.println("생산일보 집계 배치 작업 완료 (" + duration + "초 소요)");
    }
}
