/**
 * 인터페이스 수신 오케스트레이션: 소스 클라이언트 호출 → 응답 JSON → 적재 프로시저.
 */
package com.dowinsys.cost.common.iface.service.impl;

import com.dowinsys.cost.common.iface.IfEndpoint;
import com.dowinsys.cost.common.iface.IfSource;
import com.dowinsys.cost.common.iface.client.ErpApiClient;
import com.dowinsys.cost.common.iface.client.MesApiClient;
import com.dowinsys.cost.common.iface.mapper.IfLoadMapper;
import com.dowinsys.cost.common.iface.service.IfService;
import com.dowinsys.cost.common.iface.vo.IfFetchRequest;
import com.dowinsys.cost.common.iface.vo.IfFetchResult;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@Service("com.dowinsys.cost.common.iface.service.IfService")
public class IfServiceImpl implements IfService {

    private static final Logger log = LoggerFactory.getLogger(IfServiceImpl.class);

    private final ErpApiClient erp;
    private final MesApiClient mes;
    private final IfLoadMapper loadMapper;

    public IfServiceImpl(ErpApiClient erp, MesApiClient mes, IfLoadMapper loadMapper) {
        this.erp = erp;
        this.mes = mes;
        this.loadMapper = loadMapper;
    }

    @Override
    @Transactional
    public IfFetchResult fetch(IfFetchRequest req) {
        IfEndpoint ep = IfEndpoint.of(req.getKey())
                .orElseThrow(() -> new IllegalArgumentException("알 수 없는 인터페이스 key: " + req.getKey()));

        String requestId = "IF-" + ep.name() + "-" + UUID.randomUUID().toString().substring(0, 8);

        // 1) 소스 호출
        String json = (ep.source() == IfSource.MES)
                ? mes.call(ep, req.getParams())
                : erp.call(ep, req.getParams());

        if (json == null || json.isBlank()) {
            throw new IllegalStateException("응답 본문이 비어 있음");
        }

        // 2) 적재 프로시저
        int loaded = ep.useSelCode()
                ? loadMapper.loadWithSel(ep.loadProc(), json, req.getSelCode(), requestId)
                : loadMapper.loadMaster(ep.loadProc(), json, requestId);

        log.info("[IF] {} 적재 {}건 (selCode={}, requestId={})", ep.name(), loaded, req.getSelCode(), requestId);
        return IfFetchResult.ok(ep.name(), requestId, loaded);
    }
}
