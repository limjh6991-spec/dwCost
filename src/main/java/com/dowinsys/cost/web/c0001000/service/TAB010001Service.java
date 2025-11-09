/**
 * 기준정보 > 모델관리
 */
package com.dowinsys.cost.web.c0001000.service;

import org.springframework.web.multipart.MultipartFile;

import java.util.Map;

public interface TAB010001Service {
    Map<String, String> uploadExcel(MultipartFile file, String headers) throws Exception;
}