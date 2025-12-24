package com.dowinsys.cost.web.c0001000.service;

import org.springframework.web.multipart.MultipartFile;

import java.util.Map;

public interface C0001004Service {
    Map<String, String> tab1UploadExcel(MultipartFile file, String headers) throws Exception;
    Map<String, String> tab2UploadExcel(MultipartFile file, String headers) throws Exception;
    Map<String, String> tab3UploadExcel(MultipartFile file, String headers) throws Exception;
    Map<String, String> tab4UploadExcel(MultipartFile file, String headers) throws Exception;

    // 이월 데이터
    Map<String, Object> tab1CarryOver(String yyyymm, String prevYyyymm, String site) throws Exception;
    Map<String, Object> tab2CarryOver(String yyyymm, String prevYyyymm, String site) throws Exception;
    Map<String, Object> tab3CarryOver(String yyyymm, String prevYyyymm, String site) throws Exception;
}
