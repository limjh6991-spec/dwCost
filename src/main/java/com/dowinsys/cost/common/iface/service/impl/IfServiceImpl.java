/**
 * 인터페이스 수신 오케스트레이션: 소스 클라이언트 호출 → 응답 JSON → 적재 프로시저.
 */
package com.dowinsys.cost.common.iface.service.impl;

import com.dowinsys.cost.common.iface.IfEndpoint;
import com.dowinsys.cost.common.iface.IfFetchException;
import com.dowinsys.cost.common.iface.IfSource;
import com.dowinsys.cost.common.iface.client.ErpApiClient;
import com.dowinsys.cost.common.iface.client.MesApiClient;
import com.dowinsys.cost.common.iface.config.IfProperties;
import com.dowinsys.cost.common.iface.mapper.IfLoadMapper;
import com.dowinsys.cost.common.iface.service.IfService;
import com.dowinsys.cost.common.iface.vo.IfFetchRequest;
import com.dowinsys.cost.common.iface.vo.IfFetchResult;
import com.dowinsys.cost.common.closingmonth.service.CommonService;
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
    private final CommonService closingSvc;    // 마감월 가드
    private final ObjectMapper om = new ObjectMapper();

    public IfServiceImpl(ErpApiClient erp, MesApiClient mes, IfLoadMapper loadMapper, IfProperties props,
                         CommonService closingSvc) {
        this.erp = erp;
        this.mes = mes;
        this.loadMapper = loadMapper;
        this.props = props;
        this.closingSvc = closingSvc;
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

        // ★마감월 가드: 마감된 (yyyymm, site)는 적재/변환이 운영테이블(doi_*)을 덮어써 결산 데이터를
        //   훼손할 수 있으므로 소스 호출 전에 차단. (결산 프로시저와 달리 적재 인터페이스엔 가드가 없었음)
        //   site = ep.site()(HQ/VN). yyyymm 없으면(마스터 등 예외) 검사 불가 → 통과.
        String ymNorm = (yyyymm == null) ? null : yyyymm.replace("-", "");
        if (ymNorm != null && !ymNorm.isBlank() && closingSvc.isClosedMonth(ymNorm, ep.site())) {
            throw new IfFetchException(
                    "마감된 월입니다 (" + ymNorm + " / " + ep.site()
                    + "). 마감을 해제한 후 다시 적재하세요. (결산 데이터 보호를 위해 API 적재가 차단됩니다)", null);
        }

        // 진단용: 실제 전송할 요청(인증정보 마스킹). 서버 로그 미가용 대비 → 실패해도 F12 res.debug 로 확인.
        String maskedReq = (ep.source() == IfSource.ERP) ? safeMaskedReq(ep, req.getParams()) : null;

        // 1) 소스 호출
        String json;
        try {
            json = (ep.source() == IfSource.MES)
                    ? mes.call(ep, req.getParams())
                    : erp.call(ep, req.getParams());
        } catch (RuntimeException ex) {
            // 호출 자체 실패(네트워크/cert 미설정 등)도 요청 내용과 함께 화면에 노출
            throw new IfFetchException(ex.getMessage(), debugPayload(maskedReq, null));
        }

        if (json == null || json.isBlank()) {
            throw new IfFetchException("응답 본문이 비어 있음", debugPayload(maskedReq, json));
        }

        // 응답 본문에 오류(ERP ErrorMessage / MES success=false)가 있으면 실패로 처리
        // → "성공 0건"으로 숨기지 않고 실제 메시지 + 요청/응답을 화면(토스트·F12)에 노출
        try {
            assertNoResponseError(ep, json);
        } catch (RuntimeException ex) {
            throw new IfFetchException(ex.getMessage(), debugPayload(maskedReq, json));
        }

        // 2) 적재 프로시저 (SEL_CODE = 'ACTUAL')
        int loaded = ep.useSelCode()
                ? loadMapper.loadWithSel(ep.loadProc(), json, selCode, requestId)
                : loadMapper.loadMaster(ep.loadProc(), json, requestId);

        log.info("[IF] {} 적재 {}건 (yyyymm={}, selCode={}, requestId={})", ep.name(), loaded, yyyymm, selCode, requestId);

        // 3) 운영 반영: 변환 프로시저가 지정된 인터페이스는 적재 직후 자동 실행 (적재→운영 한 흐름, 수동 EXEC 불필요)
        //    ※마스터(useSelCode=false)도 xform 지정 시 실행 — @selCode='ACTUAL' 고정 전달 (예: ACCOUNT/DEPT 업서트)
        if (ep.xformProc() != null) {
            int applied = loadMapper.runXform(ep.xformProc(), yyyymm, selCode, ep.site());  // 사업장(VN/HQ) 파라미터화
            log.info("[IF] {} 변환({}) → 운영({}) {}건", ep.name(), ep.xformProc(), ep.site(), applied);
        }

        IfFetchResult result = IfFetchResult.ok(ep.name(), requestId, loaded);
        // 진단용: 마스킹 요청 + ERP/MES 실응답을 결과에 실어 화면 콘솔(F12)에서 확인 가능
        result.setDebug(debugPayload(maskedReq, json));
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

    /** ERP 마스킹 요청 생성 (실패해도 예외 없이 사유 문자열 반환) */
    private String safeMaskedReq(IfEndpoint ep, Map<String, Object> params) {
        try {
            return erp.maskedRequest(ep, params);
        } catch (Exception e) {
            return "(요청 생성 실패: " + e.getMessage() + ")";
        }
    }

    /** F12 res.debug 용 진단 페이로드: 마스킹 요청 + 실응답 (각 4KB 축약) */
    private String debugPayload(String maskedReq, String response) {
        String req = trunc(maskedReq);
        String res = trunc(response);
        return "REQUEST=" + (req == null ? "" : req) + "\n\nRESPONSE=" + (res == null ? "" : res);
    }

    private static String trunc(String s) {
        if (s == null) return null;
        return s.length() > 4000 ? s.substring(0, 4000) + " ...(truncated)" : s;
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
