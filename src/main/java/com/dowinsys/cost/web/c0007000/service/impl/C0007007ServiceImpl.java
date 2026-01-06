/**
 * 타시스템 > 유상사급
 */
package com.dowinsys.cost.web.c0007000.service.impl;

import com.dowinsys.cost.common.utils.ExcelUtils;
import com.dowinsys.cost.web.c0007000.mapper.C0007007Mapper;
import com.dowinsys.cost.web.c0007000.service.C0007007Service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.util.*;
import java.util.stream.Collectors;

@Service("com.dowinsys.cost.web.c0007000.service.C0007007")
public class C0007007ServiceImpl implements C0007007Service {

    @Autowired
    C0007007Mapper mapper;

    @Override
    public Map<String, String> tab1UploadExcel(MultipartFile file, String headers) throws Exception {
        List<String> headerList = Arrays.asList(headers.split(","));
        Map<String, String> ret = new HashMap<>();

        try {
            // 1) 엑셀 원본 그대로 읽기 (중복 제거/중복 체크 전부 안 함)
            List<Map<String, String>> list = ExcelUtils.readExcel(file, headerList, 1, true, true);

            // 2) SITE만 치환 (본사/VINA -> HQ/VN)
            list = list.stream().map(item -> {
                String site = item.get("field4");
                if (site != null) {
                    if (site.equalsIgnoreCase("본사")) {
                        item.put("field4", "HQ");
                    } else if (site.equalsIgnoreCase("VINA")) {
                        item.put("field4", "VN");
                    } else if (site.equalsIgnoreCase("HQ")) {
                        item.put("field4", "HQ");
                    } else if (site.equalsIgnoreCase("VN")) {
                        item.put("field4", "VN");
                    } else {
                        // 값이 애매하면 기본 HQ
                        item.put("field4", "HQ");
                    }
                } else {
                    item.put("field4", "HQ");
                }
                return item;
            }).collect(Collectors.toList());

            // 3) 100건 단위로 업로드만 수행 (DB 중복 체크 호출 X)
            int loopCnt = list.size() / 100;
            int remain = list.size() % 100;
            int cnt = 0;
            int retCnt = 0;

            for (int i = 1; i <= loopCnt; i++) {
                List<Map<String, String>> splitList = new ArrayList<>(100);
                for (int j = 0; j < 100; j++) {
                    splitList.add(list.get(cnt));
                    cnt++;
                }
                retCnt += mapper.tab1UploadExcel(splitList);
            }

            if (remain > 0) {
                List<Map<String, String>> splitList = new ArrayList<>(remain);
                for (int i = 1; i <= remain; i++) {
                    splitList.add(list.get(cnt));
                    cnt++;
                }
                retCnt += mapper.tab1UploadExcel(splitList);
            }

            // 4) 성공 처리
            ret.put("status", "success");
            ret.put("insertCount", String.valueOf(retCnt));
            return ret;

        } catch (Exception e) {
            throw e;
        }
    }

    @Override
    public Map<String, String> tab2UploadExcel(MultipartFile file, String headers) throws Exception {
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

            //check excel pk duplicate
            List<Map<String, String>> list3 = ExcelUtils.readExcel(file, headerList, 1, true, true);
            List<Map<String, String>> list2 = ExcelUtils.readExcel(file, headerList, 1, true, true);
            for (Map<String, String> item : list3) {
                Map<String, String> addItem = new HashMap<>();
                addItem.put("field2", item.get("field2"));
                addItem.put("field3", item.get("field3"));
                addItem.put("field4", item.get("field4"));
                addItem.put("field13", item.get("field13"));
                addItem.put("field14", item.get("field14"));
                list2.add(addItem);
            }
            List<Map<String, String>> finalList2 = list2;
            List<Map<String, String>> pkDuplicateList = list2.stream().filter(i -> Collections.frequency(finalList2, i) > 1).toList();
            //pkDuplicateList = pkDuplicateList.stream().distinct().toList();

            List<Map<String, String>> duplicateOrgList = new ArrayList<>();
            int loopCnt = list.size() / 100;
            int remain = list.size() % 100;
            int cnt = 0;
            int retCnt = 0;

            for (int i = 1; i <= loopCnt; i++) {
                List<Map<String, String>> splitList = new ArrayList<>();
                for (int j = 0; j < 100; j++) {
                    splitList.add(list.get(cnt));
                    cnt++;
                }

                List<Map<String, String>> retList = mapper.checkTab2DuplicateOrgList(splitList);
                if (retList != null) duplicateOrgList.addAll(retList);

                retCnt += mapper.tab2UploadExcel(splitList);
            }

            if (remain > 0) {
                List<Map<String, String>> splitList = new ArrayList<>();
                for (int i = 1; i <= remain; i++) {
                    splitList.add(list.get(cnt));
                    cnt++;
                }

                List<Map<String, String>> retList = mapper.checkTab2DuplicateOrgList(splitList);
                if (retList != null) duplicateOrgList.addAll(retList);

                retCnt += mapper.tab2UploadExcel(splitList);
            }

            if (!duplicateOrgList.isEmpty() || !duplicateList.isEmpty() || !pkDuplicateList.isEmpty()) {
                StringBuilder errorMessage = new StringBuilder();
                List<String> matEtcList = new ArrayList<>();
                for (Map<String, String> item : duplicateOrgList) {
                    matEtcList.add(item.get("품명"));
                }
                matEtcList = matEtcList.stream().distinct().toList();

                int index = 0;
                for (String acct : matEtcList) {
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
                    errorMessage.append("품명은 동일년월 동일사업장에 이미 존재하는 데이터로 업로드 대상이 아닙니다.");
                    if (!duplicateList.isEmpty() || !pkDuplicateList.isEmpty()) {
                        errorMessage.append("\n");
                    }
                }

                List<String> stockList2 = new ArrayList<>();
                for (Map<String, String> item : duplicateList) {
                    stockList2.add(item.get("field13"));
                }
                for (Map<String, String> item : pkDuplicateList) {
                    stockList2.add(item.get("field13"));
                }
                stockList2 = stockList2.stream().distinct().toList();

                index = 0;
                for (String cstNo : stockList2) {
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
