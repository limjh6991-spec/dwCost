/**
 * 타시스템 > 기타입출고금액 (본사, DOI_ETC_INOUT)
 *
 * ERP 「기타입출고금액조회(통합)」 엑셀을 원본 그대로 업로드한다.
 *   - 1행 제목 / 2행 헤더 / 3행 TOTAL 은 건너뛰고 4행부터 읽는다 (startRow=3, 0-based)
 *   - 기준월(yyyymm)은 파일명이 아니라 [일자] 컬럼에서 유도한다
 *   - 파일에 들어있는 월 단위로 삭제 후 재적재 (멱등)
 */
package com.dowinsys.cost.web.c0007000.service.impl;

import com.dowinsys.cost.common.utils.ExcelUtils;
import com.dowinsys.cost.component.JwtUtil;
import com.dowinsys.cost.web.c0007000.mapper.C0007017Mapper;
import com.dowinsys.cost.web.c0007000.service.C0007017Service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

@Service("com.dowinsys.cost.web.c0007000.service.C0007017")
public class C0007017ServiceImpl implements C0007017Service {

    /** 제목(1) + 헤더(2) + TOTAL(3) 을 건너뛴 첫 데이터 행 (0-based) */
    private static final int DATA_START_ROW = 3;
    private static final int BATCH_SIZE = 100;

    @Autowired
    private C0007017Mapper mapper;

    @Autowired
    private JwtUtil jwtUtil;

    @Transactional
    @Override
    public Map<String, String> uploadExcel(MultipartFile file, String headers) throws Exception {
        List<String> headerList = Arrays.asList(headers.split(","));
        Map<String, String> ret = new HashMap<>();

        List<Map<String, String>> list = ExcelUtils.readExcel(file, headerList, DATA_START_ROW, true, true);

        String editUser = jwtUtil.getUserId();
        Set<String> months = new LinkedHashSet<>();

        for (Map<String, String> item : list) {
            String yyyymm = toYyyymm(item.get("field2"));   // field2 = 일자
            if (yyyymm == null) {
                ret.put("status", "error");
                ret.put("errorMessage", "일자가 비어있거나 형식이 올바르지 않은 행이 있습니다. 원본 엑셀을 그대로 올려주세요.");
                return ret;
            }
            item.put("yyyymm", yyyymm);
            item.put("editUser", editUser);
            months.add(yyyymm);
        }

        if (list.isEmpty()) {
            ret.put("status", "error");
            ret.put("errorMessage", "업로드할 데이터가 없습니다.");
            return ret;
        }

        // 같은 월을 다시 올리면 기존 데이터를 지우고 새로 넣는다.
        for (String yyyymm : months) {
            mapper.deleteMonth(yyyymm);
        }

        int insertCount = 0;
        for (int from = 0; from < list.size(); from += BATCH_SIZE) {
            int to = Math.min(from + BATCH_SIZE, list.size());
            insertCount += mapper.uploadExcel(new ArrayList<>(list.subList(from, to)));
        }

        ret.put("status", "success");
        ret.put("insertCount", String.valueOf(insertCount));
        return ret;
    }

    /** '2026-07-01' / '2026/07/01' / '20260701' 형태에서 yyyymm 추출 */
    private String toYyyymm(String date) {
        if (date == null) return null;
        String digits = date.replaceAll("[^0-9]", "");
        return digits.length() >= 6 ? digits.substring(0, 6) : null;
    }
}
