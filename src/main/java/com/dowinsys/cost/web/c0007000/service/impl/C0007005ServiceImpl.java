/**
 * 타시스템 > 매출 정보
 */
package com.dowinsys.cost.web.c0007000.service.impl;

import com.dowinsys.cost.common.utils.ExcelUtils;
import com.dowinsys.cost.web.c0007000.mapper.C0007005Mapper;
import com.dowinsys.cost.web.c0007000.service.C0007005Service;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.util.*;
import java.util.stream.Collectors;

@Service("com.dowinsys.cost.web.c0007000.service.C0007005")
public class C0007005ServiceImpl implements C0007005Service {

    @Autowired
    C0007005Mapper mapper;

    @Override
    public Map<String, String> uploadExcel(MultipartFile file, String headers) throws Exception {
        System.out.println("uploadExcel");
        List<String> headerList = Arrays.asList(headers.split(","));
        Map<String, String> ret = new HashMap<>();

        try {
            List<Map<String, String>> list = ExcelUtils.readExcel(file, headerList, 1, true, true);
            List<Map<String, String>> finalList = list;
            List<Map<String, String>> duplicateList = list.stream().filter(i -> Collections.frequency(finalList, i) > 1).toList();
            duplicateList = duplicateList.stream().distinct().toList();
            list = list.stream().distinct().toList();
            list = list.stream().map(item -> {
                //TODO:: add SITE
                if (item.get("field4").equalsIgnoreCase("본사")) {
                    item.put("field4", "HQ");
                } else if (item.get("field4").equalsIgnoreCase("VINA")) {
                    item.put("field4", "VN");
                } else {
                    item.put("field4", "HQ");
                }

                return item;
            }).collect(Collectors.toList());

            int loopCnt = list.size() / 20;
            int remain = list.size() % 20;
            int cnt = 0;
            int retCnt = 0;

            for (int i = 1; i <= loopCnt; i++) {
                List<Map<String, String>> splitList = new ArrayList<>();
                for (int j = 0; j < 20; j++) {
                    splitList.add(list.get(cnt));
                    cnt++;
                }

                retCnt += mapper.uploadExcel(splitList);
            }

            if (remain > 0) {
                List<Map<String, String>> splitList = new ArrayList<>();
                for (int i = 1; i <= remain; i++) {
                    splitList.add(list.get(cnt));
                    cnt++;
                }

                retCnt += mapper.uploadExcel(splitList);
            }

            if (!duplicateList.isEmpty()) {
                StringBuilder errorMessage = new StringBuilder();
                errorMessage.append("중복데이터가 제거되었습니다.");

                System.out.println(errorMessage);
                ret.put("status", "error");
                ret.put("errorMessage", errorMessage.toString());
            } else {
                ret.put("status", "success");
            }

            return ret;

        } catch (Exception e) {
            throw e;
        }
    }
}
