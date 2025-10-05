/**
 * 카세트 관리 > 카세트 불출
 */
package com.dowinsys.cost.web.m0007000.service.impl;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import com.dowinsys.cost.common.utils.ExcelUtils;
import com.dowinsys.cost.web.m0007000.mapper.M0007001Mapper;
import com.dowinsys.cost.web.m0007000.service.M0007001Service;

import java.util.*;

@Service("com.dowinsys.cost.web.m0007000.service.M0007001")
public class M0007001ServiceImpl implements M0007001Service {

    @Autowired
    M0007001Mapper mapper;

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

            //check excel pk duplicate
            List<Map<String, String>> list2 = ExcelUtils.readExcel(file, headerList, 1, true, true);
            for (Map<String, String> item : list2) {
                item.remove("field2");
                item.remove("field7");
                item.remove("field8");
                item.remove("field9");
            }
            List<Map<String, String>> finalList2 = list2;
            List<Map<String, String>> pkDuplicateList = list2.stream().filter(i -> Collections.frequency(finalList2, i) > 1).toList();
            pkDuplicateList = pkDuplicateList.stream().distinct().toList();

            List<Map<String, String>> duplicateReleaseList = new ArrayList<>();
            List<Map<String, String>> uploadList = new ArrayList<>();
            for (Map<String, String> item : list) {
                int cnt = mapper.checkDuplicate(item);
                if (cnt > 0) {
                    mapper.deleteDuplicate(item);
                    duplicateReleaseList.add(item);
                }

                uploadList.add(item);

            }

            List<Map<String, String>> duplicateMasterList = new ArrayList<>();
            int loopCnt = uploadList.size() / 200;
            int remain = uploadList.size() % 200;
            int cnt = 0;
            int retCnt = 0;

            for (int i = 1; i <= loopCnt; i++) {
                List<Map<String, String>> splitList = new ArrayList<>();
                for (int j = 0; j < 200; j++) {
                    splitList.add(uploadList.get(cnt));
                    cnt++;
                }

                List<Map<String, String>> retList = mapper.checkDuplicateMasterList(splitList);
                duplicateMasterList.addAll(retList);

                retCnt += mapper.uploadExcel(splitList);
            }

            if (remain > 0) {
                List<Map<String, String>> splitList = new ArrayList<>();
                for (int i = 1; i <= remain; i++) {
                    splitList.add(uploadList.get(cnt));
                    cnt++;
                }

                List<Map<String, String>> retList = mapper.checkDuplicateMasterList(splitList);
                duplicateMasterList.addAll(retList);

                retCnt += mapper.uploadExcel(splitList);
            }

            if (!duplicateMasterList.isEmpty() || !duplicateList.isEmpty() || !duplicateReleaseList.isEmpty() || !pkDuplicateList.isEmpty()) {
                StringBuilder errorMessage = new StringBuilder();
                List<String> cstNoList = new ArrayList<>();
                for (Map<String, String> item : duplicateMasterList) {
                    cstNoList.add(item.get("cstNo"));
                }
                cstNoList = cstNoList.stream().distinct().toList();

                int index = 0;
                for (String cstNo : cstNoList) {
                    if (index == 0) {
                        errorMessage.append(cstNo);
                    } else {
                        errorMessage.append(", ");
                        if (index % 10 == 0) {
                            errorMessage.append("\n");
                        }
                        errorMessage.append(cstNo);
                    }
                    index++;
                }
                if (!duplicateMasterList.isEmpty()) {
                    errorMessage.append(" 카세트마스터 공정에 존재하는 CST_NO로 업로드 대상이 아닙니다.");
                    if (!duplicateList.isEmpty() || !duplicateReleaseList.isEmpty() || !pkDuplicateList.isEmpty()) {
                        errorMessage.append("\n");
                    }
                }

                List<String> cstNoList2 = new ArrayList<>();
                for (Map<String, String> item : duplicateReleaseList) {
                    cstNoList2.add(item.get("field6"));
                }
                cstNoList2 = cstNoList2.stream().distinct().toList();

                index = 0;
                for (String cstNo : cstNoList2) {
                    if (index == 0) {
                        errorMessage.append(cstNo);
                    } else {
                        errorMessage.append(", ");
                        if (index % 10 == 0) {
                            errorMessage.append("\n");
                        }
                        errorMessage.append(cstNo);
                    }
                    index++;
                }
                if (!duplicateReleaseList.isEmpty()) {
                    errorMessage.append(" 불출처리마스트에 존재하는 CST_NO로 삭제 후 업로드 되었습니다.");
                    if (!duplicateList.isEmpty() || !pkDuplicateList.isEmpty()) {
                        errorMessage.append("\n");
                    }
                }

                List<String> cstNoList3 = new ArrayList<>();
                for (Map<String, String> item : duplicateList) {
                    cstNoList3.add(item.get("field6"));
                }
                for (Map<String, String> item : pkDuplicateList) {
                    cstNoList3.add(item.get("field6"));
                }
                cstNoList3 = cstNoList3.stream().distinct().toList();

                index = 0;
                for (String cstNo : cstNoList3) {
                    if (index == 0) {
                        errorMessage.append(cstNo);
                    } else {
                        errorMessage.append(", ");
                        if (index % 10 == 0) {
                            errorMessage.append("\n");
                        }
                        errorMessage.append(cstNo);
                    }
                    index++;
                }
                if (!duplicateList.isEmpty() || !pkDuplicateList.isEmpty()) {
                    errorMessage.append(" 중복데이터가 제거되었습니다.");
                }

                //System.out.println(errorMessage);
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
