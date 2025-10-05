/**
 * 카세트 관리 > 카세트 마스터
 */
package com.dowinsys.cost.web.m0007000.service;

import org.springframework.web.multipart.MultipartFile;

public interface M0007005Service {
    String uploadExcel(MultipartFile file, String headers) throws Exception;
}