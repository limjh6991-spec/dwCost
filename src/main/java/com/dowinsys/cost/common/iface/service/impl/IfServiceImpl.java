/**
 * 인터페이스 수신 오케스트레이션: 소스 클라이언트 호출 → 응답 JSON → 적재 프로시저.
 */
package com.dowinsys.cost.common.iface.service.impl;

import com.dowinsys.cost.common.iface.IfEndpoint;
import com.dowinsys.cost.common.iface.IfSource;
import com.dowinsys.cost.common.iface.client.ErpApiClient;
import com.dowinsys.cost.common.iface.client.MesApiClient;
import com.dowinsys.cost.common.iface.config.IfProperties;
import com.dowinsys.cost.common.iface.mapper.IfLoadMapper;
import com.dowinsys.cost.common.iface.service.IfService;
import com.dowinsys.cost.common.iface.vo.IfFetchRequest;
import com.dowinsys.cost.common.iface.vo.IfFetchResult;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Service("com.dowinsys.cost.common.iface.service.IfService")
public class IfServiceImpl implements IfService {

    private static final Logger log = LoggerFactory.getLogger(IfServiceImpl.class);

    private final ErpApiClient erp;
    private final MesApiClient mes;
    private final IfLoadMapper loadMapper;
    private final IfProperties props;

    public IfServiceImpl(ErpApiClient erp, MesApiClient mes, IfLoadMapper loadMapper, IfProperties props) {
        this.erp = erp;
        this.mes = mes;
        this.loadMapper = loadMapper;
        this.props = props;
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

    @Override
    public Map<String, Object> status() {
        Map<String, Object> m = new LinkedHashMap<>();

        Map<String, Object> erpM = new LinkedHashMap<>();
        erpM.put("baseUrl", props.getErp().getBaseUrl());
        erpM.put("certConfigured", props.isErpCertConfigured());  // 비밀값 노출 없이 주입 여부만
        m.put("erp", erpM);

        Map<String, Object> mesM = new LinkedHashMap<>();
        mesM.put("baseUrl", props.getMes().getBaseUrl());
        m.put("mes", mesM);

        List<Map<String, Object>> eps = new ArrayList<>();
        for (IfEndpoint e : IfEndpoint.values()) {
            Map<String, Object> em = new LinkedHashMap<>();
            em.put("key", e.name());
            em.put("source", e.source().name());
            em.put("loadProc", e.loadProc());
            em.put("useSelCode", e.useSelCode());
            eps.add(em);
        }
        m.put("endpoints", eps);

        // 소스별 실호출 가능 여부 (MES=base-url만, ERP=cert까지)
        Map<String, Object> ready = new LinkedHashMap<>();
        ready.put("mes", props.getMes().getBaseUrl() != null && !props.getMes().getBaseUrl().isBlank());
        ready.put("erp", props.isErpCertConfigured());
        m.put("ready", ready);

        return m;
    }
}
