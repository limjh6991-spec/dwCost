package com.dowinsys.cost.web.c0001000.service.impl;

import com.dowinsys.cost.common.utils.ExcelUtils;
import com.dowinsys.cost.web.c0001000.mapper.C0001004Mapper;
import com.dowinsys.cost.web.c0001000.service.C0001004Service;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.util.*;
import java.util.stream.Collectors;

@Service
public class C0001004ServiceImpl implements C0001004Service {
    @Autowired
    private C0001004Mapper mapper;

    public String getPrevYyyymm(String yyyymm) {
        int year = Integer.parseInt(yyyymm.substring(0, 4));
        int month = Integer.parseInt(yyyymm.substring(4, 6));

        int prevYear = year;
        int prevMonth = month - 1;

        if (prevMonth == 0) {
            prevYear = year - 1;
            prevMonth = 12;
        }

        return String.format("%04d%02d", prevYear, prevMonth);
    }

    // Tab1
    @Override
    public Map<String, String> tab1UploadExcel(MultipartFile file, String headers) throws Exception {
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

                //TODO:: add ACCT_CLASS
                if (item.get("field5").equalsIgnoreCase("가공비")) {
                    item.put("field5", "AA");
                } else if (item.get("field5").equalsIgnoreCase("개발비")) {
                    item.put("field5", "BB");
                } else if (item.get("field5").equalsIgnoreCase("판매관리비")) {
                    item.put("field5", "CC");
                }

                return item;
            }).collect(Collectors.toList());

            //check excel pk duplicate
            List<Map<String, String>> list3 = ExcelUtils.readExcel(file, headerList, 1, true, true);
            List<Map<String, String>> list2 = new ArrayList<>();
            for (Map<String, String> item : list3) {
                Map<String, String> addItem = new HashMap<>();
                addItem.put("field2", item.get("field2"));
                addItem.put("field4", item.get("field4"));
                addItem.put("field8", item.get("field8"));
                list2.add(addItem);
            }
            List<Map<String, String>> finalList2 = list2;
            List<Map<String, String>> pkDuplicateList = list2.stream().filter(i -> Collections.frequency(finalList2, i) > 1).toList();
            pkDuplicateList = pkDuplicateList.stream().distinct().toList();

            List<Map<String, String>> duplicateOrgList = new ArrayList<>();
            int loopCnt = list.size() / 50;
            int remain = list.size() % 50;
            int cnt = 0;
            int retCnt = 0;

            for (int i = 1; i <= loopCnt; i++) {
                List<Map<String, String>> splitList = new ArrayList<>();
                for (int j = 0; j < 50; j++) {
                    splitList.add(list.get(cnt));
                    cnt++;
                }

                List<Map<String, String>> retList = mapper.checkTab1DuplicateOrgList(splitList);
                if (retList != null) duplicateOrgList.addAll(retList);

                retCnt += mapper.tab1UploadExcel(splitList);
            }

            if (remain > 0) {
                List<Map<String, String>> splitList = new ArrayList<>();
                for (int i = 1; i <= remain; i++) {
                    splitList.add(list.get(cnt));
                    cnt++;
                }

                List<Map<String, String>> retList = mapper.checkTab1DuplicateOrgList(splitList);
                if (retList != null) duplicateOrgList.addAll(retList);

                retCnt += mapper.tab1UploadExcel(splitList);
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
                    errorMessage.append("계정코드는 동일년월 동일사업장에 이미 존재하는 데이터로 업로드 대상이 아닙니다.");
                    if (!duplicateList.isEmpty() || !pkDuplicateList.isEmpty()) {
                        errorMessage.append("\n");
                    }
                }

                List<String> acctList2 = new ArrayList<>();
                for (Map<String, String> item : duplicateList) {
                    acctList2.add(item.get("field8"));
                }
                for (Map<String, String> item : pkDuplicateList) {
                    acctList2.add(item.get("field8"));
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
    
    @Override
    public Map<String, Object> tab1CarryOver(String yyyymm, String prevYyyymm, String site) throws Exception {

        Map<String, Object> result = new HashMap<>();

        // 1. 현재월 데이터 존재 여부 체크
        Map<String, Object> curParam = new HashMap<>();
        curParam.put("yyyymm", yyyymm);
        curParam.put("site", site);

        int curCnt = mapper.countTab1ByYyyymmAndSite(curParam);
        if (curCnt > 0) {
            // 이미 데이터 있음
            result.put("status", "CURRENT_EXISTS");
            return result;
        }

        // 2. 전월 데이터 조회
        Map<String, Object> prevParam = new HashMap<>();
        prevParam.put("yyyymm", prevYyyymm);
        prevParam.put("site", site);

        List<Map<String, Object>> prevList = mapper.selectTab1ByYyyymmAndSite(prevParam);

        if (prevList == null || prevList.isEmpty()) {
            // 전월 데이터 없음
            result.put("status", "NO_PREV_DATA");
            return result;
        }

        // 3. 전월 데이터를 현재월로 복사
        List<Map<String, Object>> newList = prevList.stream()
                .map(row -> {
                    Map<String, Object> copy = new HashMap<>(row);
                    copy.put("yyyymm", yyyymm);
                    return copy;
                })
                .collect(Collectors.toList());

        result.put("status", "OK");
        result.put("rows", newList);
        return result;
    }


    // Tab2
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
            List<Map<String, String>> list2 = new ArrayList<>();
            for (Map<String, String> item : list3) {
                Map<String, String> addItem = new HashMap<>();
                addItem.put("field2", item.get("field2"));
                addItem.put("field4", item.get("field4"));
                addItem.put("field5", item.get("field5"));
                list2.add(addItem);
            }
            List<Map<String, String>> finalList2 = list2;
            List<Map<String, String>> pkDuplicateList = list2.stream().filter(i -> Collections.frequency(finalList2, i) > 1).toList();
            pkDuplicateList = pkDuplicateList.stream().distinct().toList();

            List<Map<String, String>> duplicateOrgList = new ArrayList<>();
            int loopCnt = list.size() / 50;
            int remain = list.size() % 50;
            int cnt = 0;
            int retCnt = 0;

            for (int i = 1; i <= loopCnt; i++) {
                List<Map<String, String>> splitList = new ArrayList<>();
                for (int j = 0; j < 50; j++) {
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
                List<String> deptList = new ArrayList<>();
                for (Map<String, String> item : duplicateOrgList) {
                    deptList.add(item.get("dept"));
                }
                deptList = deptList.stream().distinct().toList();
                int index = 0;
                for (String dept : deptList) {
                    if (index == 0) {
                        errorMessage.append(dept);
                    } else {
                        errorMessage.append(", ");
                        if (index % 8 == 0) {
                            errorMessage.append("\n");
                        }
                        errorMessage.append(dept);
                    }
                    index++;
                }
                if (!duplicateOrgList.isEmpty()) {
                    if (index % 8 == 0) {
                        errorMessage.append("\n");
                    } else {
                        errorMessage.append(" ");
                    }
                    errorMessage.append("부서코드는 동일년도 동일사업장에 이미 존재하는 데이터로 업로드 대상이 아닙니다.");
                    if (!duplicateList.isEmpty() || !pkDuplicateList.isEmpty()) {
                        errorMessage.append("\n");
                    }
                }

                List<String> deptList2 = new ArrayList<>();
                for (Map<String, String> item : duplicateList) {
                    deptList2.add(item.get("field5"));
                }
                for (Map<String, String> item : pkDuplicateList) {
                    deptList2.add(item.get("field5"));
                }
                deptList2 = deptList2.stream().distinct().toList();

                index = 0;
                for (String cstNo : deptList2) {
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

    @Override
    public Map<String, Object> tab2CarryOver(String yyyymm, String prevYyyymm, String site) throws Exception {

        Map<String, Object> result = new HashMap<>();

        Map<String, Object> curParam = new HashMap<>();
        curParam.put("yyyymm", yyyymm);
        curParam.put("site", site);

        int curCnt = mapper.countTab2ByYyyymmAndSite(curParam);
        if (curCnt > 0) {
            result.put("status", "CURRENT_EXISTS");
            return result;
        }

        Map<String, Object> prevParam = new HashMap<>();
        prevParam.put("yyyymm", prevYyyymm);
        prevParam.put("site", site);

        List<Map<String, Object>> prevList = mapper.selectTab2ByYyyymmAndSite(prevParam);
        if (prevList == null || prevList.isEmpty()) {
            result.put("status", "NO_PREV_DATA");
            return result;
        }

        List<Map<String, Object>> newList = prevList.stream()
                .map(row -> {
                    Map<String, Object> copy = new HashMap<>(row);
                    copy.put("yyyymm", yyyymm);
                    return copy;
                })
                .collect(Collectors.toList());

        result.put("status", "OK");
        result.put("rows", newList);
        return result;
    }

    // Tab3
        @Override
        public Map<String, String> tab3UploadExcel(MultipartFile file, String headers) throws Exception {
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
                if (item.get("field3").equalsIgnoreCase("본사")) {
                    item.put("field3", "HQ");
                } else if (item.get("field3").equalsIgnoreCase("VINA")) {
                    item.put("field3", "VN");
                } else {
                    item.put("field3", "HQ");
                }

                return item;
            }).collect(Collectors.toList());

                // 2. NULL 변환
                list = list.stream().map(item -> {
                // 빈 문자열을 null로 변환
                if ("".equals(item.get("field21"))) {
                    item.put("field21", null);
                }
                if ("".equals(item.get("field22"))) {
                    item.put("field22", null);
                }
                if ("".equals(item.get("field23"))) {
                    item.put("field23", null);
                }
                if ("".equals(item.get("field26"))) {
                    item.put("field26", null);
                }
                if ("".equals(item.get("field28"))) {
                    item.put("field28", null);
                }
                return item;
            }).collect(Collectors.toList());


            //check excel pk duplicate
            List<Map<String, String>> list3 = ExcelUtils.readExcel(file, headerList, 1, true, true);
            List<Map<String, String>> list2 = new ArrayList<>();
            for (Map<String, String> item : list3) {
                Map<String, String> addItem = new HashMap<>();
                addItem.put("field2", item.get("field2"));
                addItem.put("field3", item.get("field3"));
                addItem.put("field5", item.get("field5"));
                addItem.put("field11", item.get("field11"));
                addItem.put("field15", item.get("field15"));
                list2.add(addItem);
            }
            List<Map<String, String>> finalList2 = list2;
            List<Map<String, String>> pkDuplicateList = list2.stream().filter(i -> Collections.frequency(finalList2, i) > 1).toList();
            pkDuplicateList = pkDuplicateList.stream().distinct().toList();

            List<Map<String, String>> duplicateOrgList = new ArrayList<>();
            int loopCnt = list.size() / 50;
            int remain = list.size() % 50;
            int cnt = 0;
            int retCnt = 0;

            for (int i = 1; i <= loopCnt; i++) {
                List<Map<String, String>> splitList = new ArrayList<>();
                for (int j = 0; j < 50; j++) {
                    splitList.add(list.get(cnt));
                    cnt++;
                }

                List<Map<String, String>> retList = mapper.checkTab3DuplicateOrgList(splitList);
                if (retList != null) duplicateOrgList.addAll(retList);

                retCnt += mapper.tab3UploadExcel(splitList);
            }

            if (remain > 0) {
                List<Map<String, String>> splitList = new ArrayList<>();
                for (int i = 1; i <= remain; i++) {
                    splitList.add(list.get(cnt));
                    cnt++;
                }

                List<Map<String, String>> retList = mapper.checkTab3DuplicateOrgList(splitList);
                if (retList != null) duplicateOrgList.addAll(retList);

                retCnt += mapper.tab3UploadExcel(splitList);
            }

            if (!duplicateOrgList.isEmpty() || !duplicateList.isEmpty() || !pkDuplicateList.isEmpty()) {
                StringBuilder errorMessage = new StringBuilder();
                List<String> materialList = new ArrayList<>();
                for (Map<String, String> item : duplicateOrgList) {
                    materialList.add(item.get("제품번호"));
                }
                materialList = materialList.stream().distinct().toList();
                int index = 0;
                for (String material : materialList) {
                    if (index == 0) {
                        errorMessage.append(material);
                    } else {
                        errorMessage.append(", ");
                        if (index % 8 == 0) {
                            errorMessage.append("\n");
                        }
                        errorMessage.append(material);
                    }
                    index++;
                }
                if (!duplicateOrgList.isEmpty()) {
                    if (index % 8 == 0) {
                        errorMessage.append("\n");
                    } else {
                        errorMessage.append(" ");
                    }
                    errorMessage.append("자재코드는 동일년도 동일사업장에 이미 존재하는 데이터로 업로드 대상이 아닙니다.");
                    if (!duplicateList.isEmpty() || !pkDuplicateList.isEmpty()) {
                        errorMessage.append("\n");
                    }
                }

                List<String> materialList2 = new ArrayList<>();
                for (Map<String, String> item : duplicateList) {
                    materialList2.add(item.get("field5"));
                    materialList2.add(item.get("field11"));
                    materialList2.add(item.get("field15"));
                }
                for (Map<String, String> item : pkDuplicateList) {
                    materialList2.add(item.get("field5"));
                    materialList2.add(item.get("field11"));
                    materialList2.add(item.get("field15"));
                }
                materialList2 = materialList2.stream().distinct().toList();

                index = 0;
                for (String cstNo : materialList2) {
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

    @Override
    public Map<String, Object> tab3CarryOver(String yyyymm, String prevYyyymm, String site) throws Exception {

        Map<String, Object> result = new HashMap<>();

        Map<String, Object> curParam = new HashMap<>();
        curParam.put("yyyymm", yyyymm);
        curParam.put("site", site);

        int curCnt = mapper.countTab3ByYyyymmAndSite(curParam);
        if (curCnt > 0) {
            result.put("status", "CURRENT_EXISTS");
            return result;
        }

        Map<String, Object> prevParam = new HashMap<>();
        prevParam.put("yyyymm", prevYyyymm);
        prevParam.put("site", site);

        List<Map<String, Object>> prevList = mapper.selectTab3ByYyyymmAndSite(prevParam);
        if (prevList == null || prevList.isEmpty()) {
            result.put("status", "NO_PREV_DATA");
            return result;
        }

        List<Map<String, Object>> newList = prevList.stream()
                .map(row -> {
                    Map<String, Object> copy = new HashMap<>(row);
                    copy.put("yyyymm", yyyymm);
                    return copy;
                })
                .collect(Collectors.toList());

        result.put("status", "OK");
        result.put("rows", newList);
        return result;
    }

    // Tab5
        @Override
        public Map<String, String> tab5UploadExcel(MultipartFile file, String headers) throws Exception {
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
            List<Map<String, String>> list2 = new ArrayList<>();
            for (Map<String, String> item : list3) {
                Map<String, String> addItem = new HashMap<>();
                addItem.put("field2", item.get("field2"));
                addItem.put("field4", item.get("field4"));
                addItem.put("field5", item.get("field5"));
                list2.add(addItem);
            }
            List<Map<String, String>> finalList2 = list2;
            List<Map<String, String>> pkDuplicateList = list2.stream().filter(i -> Collections.frequency(finalList2, i) > 1).toList();
            pkDuplicateList = pkDuplicateList.stream().distinct().toList();

            List<Map<String, String>> duplicateOrgList = new ArrayList<>();
            int loopCnt = list.size() / 50;
            int remain = list.size() % 50;
            int cnt = 0;
            int retCnt = 0;

            for (int i = 1; i <= loopCnt; i++) {
                List<Map<String, String>> splitList = new ArrayList<>();
                for (int j = 0; j < 50; j++) {
                    splitList.add(list.get(cnt));
                    cnt++;
                }

                List<Map<String, String>> retList = mapper.checkTab5DuplicateOrgList(splitList);
                if (retList != null) duplicateOrgList.addAll(retList);

                retCnt += mapper.tab5UploadExcel(splitList);
            }

            if (remain > 0) {
                List<Map<String, String>> splitList = new ArrayList<>();
                for (int i = 1; i <= remain; i++) {
                    splitList.add(list.get(cnt));
                    cnt++;
                }

                List<Map<String, String>> retList = mapper.checkTab5DuplicateOrgList(splitList);
                if (retList != null) duplicateOrgList.addAll(retList);

                retCnt += mapper.tab5UploadExcel(splitList);
            }

            if (!duplicateOrgList.isEmpty() || !duplicateList.isEmpty() || !pkDuplicateList.isEmpty()) {
                StringBuilder errorMessage = new StringBuilder();
                List<String> modelList = new ArrayList<>();
                for (Map<String, String> item : duplicateOrgList) {
                    modelList.add(item.get("model"));
                }
                modelList = modelList.stream().distinct().toList();
                int index = 0;
                for (String model : modelList) {
                    if (index == 0) {
                        errorMessage.append(model);
                    } else {
                        errorMessage.append(", ");
                        if (index % 8 == 0) {
                            errorMessage.append("\n");
                        }
                        errorMessage.append(model);
                    }
                    index++;
                }
                if (!duplicateOrgList.isEmpty()) {
                    if (index % 8 == 0) {
                        errorMessage.append("\n");
                    } else {
                        errorMessage.append(" ");
                    }
                    errorMessage.append("면적기준정보는 동일년도 동일사업장에 이미 존재하는 데이터로 업로드 대상이 아닙니다.");
                    if (!duplicateList.isEmpty() || !pkDuplicateList.isEmpty()) {
                        errorMessage.append("\n");
                    }
                }

                List<String> modelList2 = new ArrayList<>();
                for (Map<String, String> item : duplicateList) {
                    modelList2.add(item.get("field5"));
                }
                for (Map<String, String> item : pkDuplicateList) {
                    modelList2.add(item.get("field5"));
                }
                modelList2 = modelList2.stream().distinct().toList();

                index = 0;
                for (String cstNo : modelList2) {
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

    @Override
    public Map<String, Object> tab5CarryOver(String yyyymm, String prevYyyymm, String site) throws Exception {

        Map<String, Object> result = new HashMap<>();

        Map<String, Object> curParam = new HashMap<>();
        curParam.put("yyyymm", yyyymm);
        curParam.put("site", site);

        int curCnt = mapper.countTab5ByYyyymmAndSite(curParam);
        if (curCnt > 0) {
            result.put("status", "CURRENT_EXISTS");
            return result;
        }

        Map<String, Object> prevParam = new HashMap<>();
        prevParam.put("yyyymm", prevYyyymm);
        prevParam.put("site", site);

        List<Map<String, Object>> prevList = mapper.selectTab5ByYyyymmAndSite(prevParam);
        if (prevList == null || prevList.isEmpty()) {
            result.put("status", "NO_PREV_DATA");
            return result;
        }

        List<Map<String, Object>> newList = prevList.stream()
                .map(row -> {
                    Map<String, Object> copy = new HashMap<>(row);
                    copy.put("yyyymm", yyyymm);
                    return copy;
                })
                .collect(Collectors.toList());

        result.put("status", "OK");
        result.put("rows", newList);
        return result;
    }
}    
