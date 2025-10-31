/**
 * 타시스템 > 매출 정보
 */
package com.dowinsys.cost.web.c0007000.service;

import org.springframework.web.multipart.MultipartFile;

import java.util.Map;

public interface C0007005Service {
    Map<String, String> uploadExcel(MultipartFile file, String headers) throws Exception;
}