/**
 * 타시스템 > 불량반품
 */
    package com.dowinsys.cost.web.c0007000.service;

    import java.util.List;
    import java.util.Map;

    public interface C0007009Service {

        // 1) 불량반품 데이터 조회
        List<Map<String, Object>> getRmaDataList(Map<String, Object> param);

        // 2) 입력
        void insertRmaData(Map<String, Object> param);

        // 3) 수정
        void updateRmaData(Map<String, Object> param);

        // 4) 삭제
        void deleteRmaData(Map<String, Object> param);

        // 5) 팝업
        List<Map<String, Object>> getModelPopup(Map<String, Object> param);
    }