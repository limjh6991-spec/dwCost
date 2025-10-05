/**
 * 카세트 관리 > 카세트 마스터
 */
package com.dowinsys.cost.web.m0007000.service.impl;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import com.dowinsys.cost.common.utils.ExcelUtils;
import com.dowinsys.cost.web.m0007000.mapper.M0007005Mapper;
import com.dowinsys.cost.web.m0007000.service.M0007005Service;

import java.util.Arrays;
import java.util.List;
import java.util.Map;

@Service("com.dowinsys.cost.web.m0007000.service.M0007005")
public class M0007005ServiceImpl implements M0007005Service {

    @Autowired
    M0007005Mapper mapper;

    @Override
    public String uploadExcel(MultipartFile file, String headers) throws Exception {
        List<String> headerList = Arrays.asList(headers.split(","));

        List<Map<String, String>> list = ExcelUtils.readExcel(file, headerList, 1, true, true);
        int insertCnt = 0;
        int uploadCnt = 0;
        int failCnt = 0;
        for (Map<String, String> item : list) {
            try {
                mapper.uploadExcel(item);
                insertCnt++;
            } catch (Exception e) {
                if (e.getMessage() != null && e.getMessage().contains("Cannot insert duplicate key")) {
                    mapper.uploadExcelUpdate(item);
                    uploadCnt++;
                } else {
                    failCnt++;
                }
            }
        }
        String ret = "";
        if (insertCnt > 0) ret += insertCnt + "건 추가 ";
        if (uploadCnt > 0) ret += uploadCnt + "건 업데이트 ";
        if (failCnt > 0) ret += failCnt + "건 실패 ";
        if (insertCnt > 0 || uploadCnt > 0 || failCnt > 0) {
            ret += "되었습니다.";
        } else {
            ret = "File upload failed";
        }

        return ret;
    }
}
