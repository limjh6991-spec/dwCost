/**
 * 기준정보 > 모델관리
 */
package com.dowinsys.cost.web.c0007000.service;

import org.springframework.web.multipart.MultipartFile;

import java.util.Map;

public interface C0007007Service {
    Map<String, String> tab1UploadExcel(MultipartFile file, String headers) throws Exception;
    Map<String, String> tab2UploadExcel(MultipartFile file, String headers) throws Exception;
}