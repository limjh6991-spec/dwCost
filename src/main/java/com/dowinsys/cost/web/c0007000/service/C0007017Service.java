/**
 * 타시스템 > 기타입출고금액 (본사)
 */
package com.dowinsys.cost.web.c0007000.service;

import org.springframework.web.multipart.MultipartFile;

import java.util.Map;

public interface C0007017Service {
    Map<String, String> uploadExcel(MultipartFile file, String headers) throws Exception;
}
