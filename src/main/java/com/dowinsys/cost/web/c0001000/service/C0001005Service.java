/**
 * 기준정보 > 제품기준정보
 */
package com.dowinsys.cost.web.c0001000.service;

import org.springframework.web.multipart.MultipartFile;

import java.util.Map;

public interface C0001005Service {
    Map<String, String> uploadExcel(MultipartFile file, String headers) throws Exception;
}