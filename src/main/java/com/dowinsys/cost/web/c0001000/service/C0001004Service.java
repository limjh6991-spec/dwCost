package com.dowinsys.cost.web.c0001000.service;

import org.springframework.web.multipart.MultipartFile;

import java.util.Map;

public interface C0001004Service {
    Map<String, String> tab1UploadExcel(MultipartFile file, String headers) throws Exception;

    Object selectTab2GridData(Map<String, Object> params);
    Object insertTab2Data(Map<String, Object> body);
    Object updateTab2Data(Map<String, Object> body);
    Object deleteTab2Data(Map<String, Object> body);

    Object selectTab3GridData(Map<String, Object> params);
    Object insertTab3Data(Map<String, Object> body);
    Object updateTab3Data(Map<String, Object> body);
    Object deleteTab3Data(Map<String, Object> body);

    Object selectTab5GridData(Map<String, Object> params);
    Object insertTab5Data(Map<String, Object> body);
    Object updateTab5Data(Map<String, Object> body);
    Object deleteTab5Data(Map<String, Object> body);
}
