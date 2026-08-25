package com.dowinsys.cost.common.closingmonth.service;

public interface CommonService {
    /** @param site 사업장(HQ/VN). null/빈값이면 사업장 무관(어느 쪽이든 마감 시 차단 — 구버전 호환) */
    boolean isClosedMonth(String yyyymm, String site);
}
