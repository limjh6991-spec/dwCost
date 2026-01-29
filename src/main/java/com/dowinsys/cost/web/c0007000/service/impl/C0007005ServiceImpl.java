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
        List<String> headerList = Arrays.asList(headers.split(","));
        Map<String, String> ret = new HashMap<>();

        try {
            List<Map<String, String>> list = ExcelUtils.readExcel(file, headerList, 1, true, true);
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

            List<Map<String, String>> duplicateOrgList = new ArrayList<>();
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

                List<Map<String, String>> retList = mapper.checkduplicateOrgList(splitList);
                if (retList != null) duplicateOrgList.addAll(retList);

                if (retList != null && !retList.isEmpty()) {
                    Set<String> exists = retList.stream()
                            .map(x -> x.get("거래명세서번호"))
                            .filter(Objects::nonNull)
                            .collect(Collectors.toSet());

                    splitList = splitList.stream()
                            .filter(x -> !exists.contains(x.get("거래명세서번호")))
                            .collect(Collectors.toList());
                }

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

            if (!duplicateOrgList.isEmpty()) {
                StringBuilder errorMessage = new StringBuilder();
                List<String> acctList = new ArrayList<>();
                for (Map<String, String> item : duplicateOrgList) {
                    acctList.add(item.get("거래명세서번호"));
                }
                acctList = acctList.stream().distinct().toList();

                int index = 0;
                for (String acct : acctList) {
                    if (index == 0) {
                        errorMessage.append(acct);
                    } else {
                        errorMessage.append(", ");
                        if (index % 6 == 0) {
                            errorMessage.append("\n");
                        }
                        errorMessage.append(acct);
                    }
                    index++;
                }
                if (!duplicateOrgList.isEmpty()) {
                    if (index % 6 == 0) {
                        errorMessage.append("\n");
                    } else {
                        errorMessage.append(" ");
                    }
                    errorMessage.append("거래명세서번호는 이미 존재하는 데이터로 업로드 대상이 아닙니다.");
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
    public Map<String, String> uploadExcel2(MultipartFile file, String headers) throws Exception {
        List<String> headerList = Arrays.asList(headers.split(","));
        Map<String, String> ret = new HashMap<>();

        try {
            List<Map<String, String>> list = ExcelUtils.readExcel(file, headerList, 1, true, true);
            list = list.stream().map(item -> {
                // SITE 매핑
                if (item.get("field4").equalsIgnoreCase("본사")) {
                    item.put("field4", "HQ");
                } else if (item.get("field4").equalsIgnoreCase("VINA")) {
                    item.put("field4", "VN");
                } else {
                    item.put("field4", "HQ");
                }
                return item;
            }).collect(Collectors.toList());

            List<Map<String, String>> duplicateOrgList = new ArrayList<>();
            int loopCnt = list.size() / 20;
            int remain = list.size() % 20;
            int cnt = 0;

            for (int i = 1; i <= loopCnt; i++) {
                List<Map<String, String>> splitList = new ArrayList<>();
                for (int j = 0; j < 20; j++) {
                    splitList.add(list.get(cnt));
                    cnt++;
                }

                List<Map<String, String>> retList = mapper.checkduplicateOrgList2(splitList);
                if (retList != null) duplicateOrgList.addAll(retList);

                if (retList != null && !retList.isEmpty()) {
                    Set<String> exists = retList.stream()
                            .map(x -> x.get("Invoice관리번호"))
                            .filter(Objects::nonNull)
                            .map(String::trim)
                            .collect(Collectors.toSet());

                    splitList = splitList.stream()
                            .filter(x -> {
                                String invMgmt = x.get("field9");
                                invMgmt = (invMgmt == null) ? "" : invMgmt.trim();
                                return !exists.contains(invMgmt);
                            })
                            .collect(Collectors.toList());
                }

                mapper.uploadExcel2(splitList);
            }

            if (remain > 0) {
                List<Map<String, String>> splitList = new ArrayList<>();
                for (int i = 1; i <= remain; i++) {
                    splitList.add(list.get(cnt));
                    cnt++;
                }

                List<Map<String, String>> retList = mapper.checkduplicateOrgList2(splitList);
                if (retList != null) duplicateOrgList.addAll(retList);

                if (retList != null && !retList.isEmpty()) {
                    Set<String> exists = retList.stream()
                            .map(x -> x.get("Invoice관리번호"))
                            .filter(Objects::nonNull)
                            .map(String::trim)
                            .collect(Collectors.toSet());

                    splitList = splitList.stream()
                            .filter(x -> {
                                String invMgmt = x.get("field9");
                                invMgmt = (invMgmt == null) ? "" : invMgmt.trim();
                                return !exists.contains(invMgmt);
                            })
                            .collect(Collectors.toList());
                }

                mapper.uploadExcel2(splitList);
            }

            if (!duplicateOrgList.isEmpty()) {
                StringBuilder errorMessage = new StringBuilder();
                List<String> acctList = new ArrayList<>();
                for (Map<String, String> item : duplicateOrgList) {
                    acctList.add(item.get("Invoice관리번호"));
                }
                acctList = acctList.stream().filter(Objects::nonNull).map(String::trim).distinct().toList();

                int index = 0;
                for (String acct : acctList) {
                    if (index == 0) errorMessage.append(acct);
                    else {
                        errorMessage.append(", ");
                        if (index % 6 == 0) errorMessage.append("\n");
                        errorMessage.append(acct);
                    }
                    index++;
                }
                if (index % 6 == 0) errorMessage.append("\n");
                else errorMessage.append(" ");
                errorMessage.append("Invoice관리번호는 이미 존재하는 데이터로 업로드 대상이 아닙니다.");

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
