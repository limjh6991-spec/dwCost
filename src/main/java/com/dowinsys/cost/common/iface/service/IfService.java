/**
 * 인터페이스 수신 오케스트레이션 서비스.
 */
package com.dowinsys.cost.common.iface.service;

import com.dowinsys.cost.common.iface.vo.IfFetchRequest;
import com.dowinsys.cost.common.iface.vo.IfFetchResult;

public interface IfService {

    /** 호출 → 적재 (한 흐름). */
    IfFetchResult fetch(IfFetchRequest req);
}
