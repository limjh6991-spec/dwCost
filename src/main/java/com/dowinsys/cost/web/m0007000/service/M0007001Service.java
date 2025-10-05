/**
 * 카세트 관리 > 카세트 불출
 */
package com.dowinsys.cost.web.m0007000.service;

import org.springframework.web.multipart.MultipartFile;

import java.util.Map;

public interface M0007001Service {
    Map<String, String> uploadExcel(MultipartFile file, String headers) throws Exception;
}