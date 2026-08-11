/**
 * 인터페이스 수신 오케스트레이션 서비스.
 */
package com.dowinsys.cost.common.iface.service;

import com.dowinsys.cost.common.iface.vo.IfFetchRequest;
import com.dowinsys.cost.common.iface.vo.IfFetchResult;

import java.util.Map;

public interface IfService {

    /** 호출 → 적재 (한 흐름). */
    IfFetchResult fetch(IfFetchRequest req);

    /** 설정/준비 상태 (cert 주입 여부·base-url·인터페이스 목록). 비밀값은 노출하지 않음. */
    Map<String, Object> status();
}
