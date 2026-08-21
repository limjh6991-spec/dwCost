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
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

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
    private final ObjectMapper om = new ObjectMapper();

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

        // 화면은 selCode='ACTUAL' + yyyymm 을 분리해 보낸다.
        // VN 인터페이스 적재/운영 반영은 결산코드 'ACTUAL' 고정. (구버전 핸들러 폴백: selCode 자리에 년월)
        String yyyymm  = req.getYyyymm() != null ? req.getYyyymm() : req.getSelCode();
        String selCode = "ACTUAL";           // 적재(스테이징)·운영 공통 결산코드 고정

        // 1) 소스 호출
        String json = (ep.source() == IfSource.MES)
                ? mes.call(ep, req.getParams())
                : erp.call(ep, req.getParams());

        if (json == null || json.isBlank()) {
            throw new IllegalStateException("응답 본문이 비어 있음");
        }

        // 응답 본문에 오류(ERP ErrorMessage / MES success=false)가 있으면 실패로 처리
        // → "성공 0건"으로 숨기지 않고 실제 메시지를 화면 토스트에 노출
        assertNoResponseError(ep, json);

        // 2) 적재 프로시저 (SEL_CODE = 'ACTUAL')
        int loaded = ep.useSelCode()
                ? loadMapper.loadWithSel(ep.loadProc(), json, selCode, requestId)
                : loadMapper.loadMaster(ep.loadProc(), json, requestId);

        log.info("[IF] {} 적재 {}건 (yyyymm={}, selCode={}, requestId={})", ep.name(), loaded, yyyymm, selCode, requestId);

        // 3) 운영 반영: 변환 프로시저가 지정된 인터페이스는 적재 직후 자동 실행 (적재→운영 한 흐름, 수동 EXEC 불필요)
        if (ep.xformProc() != null && ep.useSelCode()) {
            int applied = loadMapper.runXform(ep.xformProc(), yyyymm, selCode, "VN");
            log.info("[IF] {} 변환({}) → 운영 {}건", ep.name(), ep.xformProc(), applied);
        }

        IfFetchResult result = IfFetchResult.ok(ep.name(), requestId, loaded);
        // 진단용: ERP/MES 실응답을 결과에 실어 화면 콘솔(F12)에서 확인 가능 (서버 로그 미가용 대비, 4KB 축약)
        result.setDebug(json.length() > 4000 ? json.substring(0, 4000) + " ...(truncated)" : json);
        return result;
    }

    /**
     * ERP/MES 응답 본문에 오류가 담겨 있으면 예외로 던져 실패 처리한다.
     * (ERP가 권한오류 등을 200 OK + ErrorMessage 로 주고, MES는 success=false 로 주므로
     *  적재 0건 '성공'으로 위장되는 것을 방지 → 실제 메시지를 화면에 노출)
     */
    private void assertNoResponseError(IfEndpoint ep, String json) {
        JsonNode root;
        try {
            root = om.readTree(json);
        } catch (Exception e) {
            return; // 파싱 불가 응답은 적재 단계에 위임
        }
        if (ep.source() == IfSource.MES) {
            JsonNode ok = root.get("success");
            if (ok != null && ok.isBoolean() && !ok.asBoolean()) {
                String code = root.hasNonNull("code") ? root.get("code").asText() : "";
                String msg = root.hasNonNull("message") ? root.get("message").asText() : "";
                throw new IllegalStateException("MES 오류" + (code.isBlank() ? "" : "(" + code + ")") + ": " + msg);
            }
        } else {
            JsonNode err = root.get("ErrorMessage");
            if (err != null && err.isArray() && err.size() > 0) {
                JsonNode first = err.get(0);
                String status = first.hasNonNull("Status") ? first.get("Status").asText() : "";
                String result = first.hasNonNull("Result") ? first.get("Result").asText() : first.toString();
                // Result 형식 예: "50000|권한없음 메시지|서비스경로|16" → 사람이 읽을 부분 추출
                String[] seg = result.split("\\|");
                String msg = seg.length > 1 ? seg[1] : result;
                // 진단: 실제 보낸 라우팅/권한 키(배포 반영 여부·userSeq 확인) + ERP 원문 Result(서비스경로 포함) 노출
                String sent = String.format(" [보낸값 serviceSeq=%s pgmSeq=%s methodSeq=%s userSeq=%s]",
                        ep.serviceSeq(), ep.pgmSeq(), ep.methodSeq(), ep.userSeq());
                throw new IllegalStateException("ERP 오류" + (status.isBlank() ? "" : "(" + status + ")") + ": " + msg
                        + sent + " [ERP원문 Result: " + result + "]");
            }
        }
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
