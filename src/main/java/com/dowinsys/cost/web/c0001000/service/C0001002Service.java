/**
*	기준정보 > 부서관리
*/
package com.dowinsys.cost.web.c0001000.service;

import org.springframework.web.multipart.MultipartFile;
import java.util.Map;

public interface C0001002Service {
    Map<String, String> uploadExcel(MultipartFile file, String headers) throws Exception;
}