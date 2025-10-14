package com.dowinsys.cost.common.batch.service;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import com.dowinsys.cost.common.enums.MatTypeEnum;
import com.dowinsys.cost.web.m0001000.service.M0001001Service;
import com.dowinsys.cost.web.m0001000.service.M0001002Service;
import com.dowinsys.cost.web.m0001000.service.M0001003Service;
import com.dowinsys.cost.web.m0001000.service.M0001004Service;
import com.dowinsys.cost.web.m0001000.service.M0001005Service;
import com.dowinsys.cost.web.m0001000.service.M0001006Service;
import com.dowinsys.cost.web.m0001000.service.M0001007Service;
import com.dowinsys.cost.web.m0001000.service.M0001008Service;
import com.dowinsys.cost.web.m0001000.service.M0001009Service;

@Component
public class BatchMatScheduler {
	/*
	@Value("${batch.matScheduler.enabled}")
    private boolean batchMatSchedulerEnabled;
	
	@Autowired
	M0001001Service serviceM0001001;	
	@Autowired
	M0001002Service serviceM0001002;
	@Autowired
	M0001003Service serviceM0001003;
	@Autowired
	M0001004Service serviceM0001004;	
	@Autowired
	M0001005Service serviceM0001005;
	@Autowired
	M0001006Service serviceM0001006;
	@Autowired
	M0001007Service serviceM0001007;	
	@Autowired
	M0001008Service serviceM0001008;
	@Autowired
	M0001009Service serviceM0001009;
	
	@Scheduled(cron = "0 5 8 * * *")
    public void matSummaryBatchJob() {
		
		String stockDate = LocalDate.now().minusDays(1).format(DateTimeFormatter.ofPattern("yyyyMMdd"));
		
        System.out.println(String.format("***** 자재관리 - 재고일 %s 전산재고 집계 시작 %s *****", stockDate, java.time.LocalDateTime.now()));
        System.out.println("batchMatSchedulerEnabled: " + batchMatSchedulerEnabled);                       

        long startTime = System.nanoTime(); // 시작 시간
        
        if(batchMatSchedulerEnabled) {
        	executeMatSummary(stockDate);
        }
        
        long endTime = System.nanoTime(); // 종료 시간
        long duration = (endTime - startTime) / 1_000_000_000; // 나노초 -> 초 변환
        
        System.out.println("* 자재 전산재고 집계 소요시간 (" + duration + "초 소요)");
        System.out.println(String.format("***** 자재관리 - 재고일 %s 전산재고 집계 종료 %s} *****", stockDate, java.time.LocalDateTime.now()));
    }
	
	private void executeMatSummary(String stockDate) {	
		
        Map<String, Object> params = new HashMap<>();
        Map<String, Object> resultData = new HashMap<>();
        
        params.put("stockDate", stockDate);
        params.put("workerId", "SYSTEM");
        params.put("workerName", "SYS_BATCH");	
        
        int processOrder = 0;
		
		for ( MatTypeEnum matType : MatTypeEnum.values() ) {
            params.put("matCategoryCode", matType.getMatCategoryCode());
            params.put("matTypeCode", matType.getMatTypeCode());
            
            processOrder++;
            System.out.println(String.format("%s) %s 전산재고 집계 %s",  processOrder, matType.getMatName(), java.time.LocalDateTime.now()));	
            
            if (  matType == MatTypeEnum.GLASS ) {
            	resultData = serviceM0001001.saveSummaryData(params);
            }
            else if (  matType == MatTypeEnum.RESIN ) {
            	resultData = serviceM0001002.saveSummaryData(params);
            }   
            else if (  matType == MatTypeEnum.TOOL ) {
            	resultData = serviceM0001003.saveSummaryData(params);
            }
            else if (  matType == MatTypeEnum.FILM ) {
            	resultData = serviceM0001004.saveSummaryData(params);
            }  
            else if (  matType == MatTypeEnum.TRAY ) {
            	resultData = serviceM0001005.saveSummaryData(params);
            } 
            else if (  matType == MatTypeEnum.CHEMICAL ) {
            	resultData = serviceM0001006.saveSummaryData(params);
            }
            else if (  matType == MatTypeEnum.FILTER ) {
            	resultData = serviceM0001007.saveSummaryData(params);
            }             
            else if (  matType == MatTypeEnum.DUMMY ) {
            	resultData = serviceM0001008.saveSummaryData(params);
            }  
            else if (  matType == MatTypeEnum.ETC ) {
            	resultData = serviceM0001009.saveSummaryData(params);
            }                 
			
			if ("SUCCESS".equals(resultData.get("resultCode"))) {
				System.out.println(String.format("    SUCCESS : %s %s 전산재고 집계", stockDate, matType.getMatName()));		
			}
			else {
				if ("NOT_EXISTS_PRE".equals(resultData.get("resultCode"))) {
					String msg = "이전일 전산집계가 되지 않아 진행을 할 수 없습니다.";
					System.out.println(String.format("    FAIL : %s %s 전산재고 집계 - %s",  stockDate, matType.getMatName(), msg));
				}
			}
		}
		
	} */
}
