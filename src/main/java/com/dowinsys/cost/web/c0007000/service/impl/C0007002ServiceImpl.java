/**
 * 타시스템 > 자재투입정보
 */
package com.dowinsys.cost.web.c0007000.service.impl;

import com.dowinsys.cost.common.utils.ExcelUtils;
import com.dowinsys.cost.web.c0007000.mapper.C0007002Mapper;
import com.dowinsys.cost.web.c0007000.service.C0007002Service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.util.*;
import java.util.stream.Collectors;

@Service("com.dowinsys.cost.web.c0007000.service.C0007002")
public class C0007002ServiceImpl implements C0007002Service {

    @Autowired
    C0007002Mapper mapper;

    @Override
    public Map<String, String> uploadExcel(MultipartFile file, String headers) throws Exception {
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
                } else if (item.get("field4").equalsIgnoreCase("베트남")) {
                    item.put("field4", "VN");
                } else {
                    item.put("field4", "HQ");
                }

                return item;
            }).collect(Collectors.toList());

            //check excel pk duplicate
            List<Map<String, String>> list2 = ExcelUtils.readExcel(file, headerList, 1, true, true);
            for (Map<String, String> item : list2) {
                item.remove("field1");
                item.remove("field3");
                item.remove("field5");
                item.remove("field7");
                item.remove("field8");
                item.remove("field9");
                item.remove("field10");
            }
            List<Map<String, String>> finalList2 = list2;
            List<Map<String, String>> pkDuplicateList = list2.stream().filter(i -> Collections.frequency(finalList2, i) > 1).toList();
            pkDuplicateList = pkDuplicateList.stream().distinct().toList();

            List<Map<String, String>> duplicateOrgList = new ArrayList<>();
            int loopCnt = list.size() / 200;
            int remain = list.size() % 200;
            int cnt = 0;
            int retCnt = 0;

            for (int i = 1; i <= loopCnt; i++) {
                List<Map<String, String>> splitList = new ArrayList<>();
                for (int j = 0; j < 200; j++) {
                    splitList.add(list.get(cnt));
                    cnt++;
                }

                List<Map<String, String>> retList = mapper.checkduplicateOrgList(splitList);
                if (retList != null) duplicateOrgList.addAll(retList);

                retCnt += mapper.uploadExcel(splitList);
            }

            if (remain > 0) {
                List<Map<String, String>> splitList = new ArrayList<>();
                for (int i = 1; i <= remain; i++) {
                    splitList.add(list.get(cnt));
                    cnt++;
                }

                List<Map<String, String>> retList = mapper.checkduplicateOrgList(splitList);
                if (retList != null) duplicateOrgList.addAll(retList);

                retCnt += mapper.uploadExcel(splitList);
            }

            if (!duplicateOrgList.isEmpty() || !duplicateList.isEmpty() || !pkDuplicateList.isEmpty()) {
                StringBuilder errorMessage = new StringBuilder();
                List<String> acctList = new ArrayList<>();
                for (Map<String, String> item : duplicateOrgList) {
                    acctList.add(item.get("acct"));
                }
                acctList = acctList.stream().distinct().toList();

                int index = 0;
                for (String acct : acctList) {
                    if (index == 0) {
                        errorMessage.append(acct);
                    } else {
                        errorMessage.append(", ");
                        if (index % 8 == 0) {
                            errorMessage.append("\n");
                        }
                        errorMessage.append(acct);
                    }
                    index++;
                }
                if (!duplicateOrgList.isEmpty()) {
                    if (index % 8 == 0) {
                        errorMessage.append("\n");
                    } else {
                        errorMessage.append(" ");
                    }
                    errorMessage.append("계정코드는 동일년도 동일사업장에 이미 존재하는 데이터로 업로드 대상이 아닙니다.");
                    if (!duplicateList.isEmpty() || !pkDuplicateList.isEmpty()) {
                        errorMessage.append("\n");
                    }
                }

                List<String> acctList2 = new ArrayList<>();
                for (Map<String, String> item : duplicateList) {
                    acctList2.add(item.get("field6"));
                }
                for (Map<String, String> item : pkDuplicateList) {
                    acctList2.add(item.get("field6"));
                }
                acctList2 = acctList2.stream().distinct().toList();

                index = 0;
                for (String cstNo : acctList2) {
                    if (index == 0) {
                        errorMessage.append(cstNo);
                    } else {
                        errorMessage.append(", ");
                        if (index % 8 == 0) {
                            errorMessage.append("\n");
                        }
                        errorMessage.append(cstNo);
                    }
                    index++;
                }
                if (!duplicateList.isEmpty() || !pkDuplicateList.isEmpty()) {
                    if (index % 8 == 0) {
                        errorMessage.append("\n");
                    } else {
                        errorMessage.append(" ");
                    }
                    errorMessage.append("중복데이터가 제거되었습니다.");
                }

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
