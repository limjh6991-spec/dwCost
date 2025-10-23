/**
 * 타시스템 > 부서별,계정별 비용
 */
package com.dowinsys.cost.web.c0007000.service;

import org.springframework.web.multipart.MultipartFile;

import java.util.Map;

public interface C0007001Service {
    Map<String, String> uploadExcel(MultipartFile file, String headers) throws Exception;
}