/**
 * 영림원 K-System(ERP) 호출 클라이언트.
 * 요청 = 중첩 ROOT 봉투(cert 인증정보 + data.ROOT.DataBlock1[화면 조회조건]).
 * 응답 본문(JSON 문자열)을 그대로 반환 → 적재 프로시저가 $.DataBlock1 파싱.
 * 인증정보는 IfProperties(env 외부화)에서만 읽는다.
 */
package com.dowinsys.cost.common.iface.client;

import com.dowinsys.cost.common.iface.IfEndpoint;
import com.dowinsys.cost.common.iface.config.IfProperties;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Component
public class ErpApiClient {

    private static final Logger log = LoggerFactory.getLogger(ErpApiClient.class);

    private final RestTemplate rest;
    private final IfProperties props;
    private final ObjectMapper om = new ObjectMapper();

    public ErpApiClient(@Qualifier("ifRestTemplate") RestTemplate rest, IfProperties props) {
        this.rest = rest;
        this.props = props;
    }

    /**
     * @param endpoint     대상 인터페이스
     * @param dataBlock    화면에서 넘어온 조회조건(DataBlock1[0] 로 들어감)
     * @return 응답 JSON 본문 문자열
     */
    public String call(IfEndpoint endpoint, Map<String, Object> dataBlock) {
        IfProperties.Erp erp = props.getErp();
        String base = erp.baseUrlFor(endpoint.site());   // HQ→hqBaseUrl, VN→baseUrl (없으면 baseUrl 폴백)
        if (base == null || base.isBlank()) {
            throw new IllegalStateException("iface.erp." + ("HQ".equals(endpoint.site()) ? "hq-base-url" : "base-url") + " 미설정");
        }
        if (!props.isErpCertConfigured()) {
            throw new IllegalStateException(
                "ERP 인증정보(certId/certKey/dsnOper/dsnBis) 미설정 - 환경변수로 주입 필요");
        }

        String url = base + endpoint.path();
        String body = buildEnvelope(erp, endpoint, dataBlock);

        // 진단용: 실제 전송 요청 로깅 (인증정보 마스킹)
        log.info("[ERP-REQ] {} serviceSeq={} pgmSeq={} methodSeq={} POST {}",
                endpoint.name(), endpoint.serviceSeq(), endpoint.pgmSeq(), endpoint.methodSeq(), url);
        log.info("[ERP-REQ] {} body={}", endpoint.name(), maskSecrets(body, erp));

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        HttpEntity<String> req = new HttpEntity<>(body, headers);

        ResponseEntity<String> res = rest.postForEntity(url, req, String.class);
        log.info("[ERP-RES] {} status={} body={}", endpoint.name(), res.getStatusCode(), res.getBody());
        return res.getBody();
    }

    /** 진단용: 실제 전송할 봉투를 인증정보 마스킹한 문자열로 반환 (F12 debug 노출용, 비밀값 미포함) */
    public String maskedRequest(IfEndpoint endpoint, Map<String, Object> dataBlock) {
        IfProperties.Erp erp = props.getErp();
        return maskSecrets(buildEnvelope(erp, endpoint, dataBlock), erp);
    }

    /** 영림원 봉투 구성: { "ROOT": { cert..., serviceSeq/pgmSeq(인터페이스별), "data": { "ROOT": { "DataBlock1": [dataBlock] } } } } */
    private String buildEnvelope(IfProperties.Erp erp, IfEndpoint ep, Map<String, Object> dataBlock) {
        Map<String, Object> root = new LinkedHashMap<>();
        root.put("certId", erp.getCertId());
        root.put("certKey", erp.getCertKey());
        root.put("dsnOper", erp.getDsnOper());
        root.put("dsnBis", erp.getDsnBis());
        root.put("companySeq", erp.getCompanySeq());
        root.put("languageSeq", ep.languageSeq() != null ? ep.languageSeq() : erp.getLanguageSeq());
        root.put("securityType", 0);
        root.put("userId", "");
        // 인터페이스별 seq (InterFace 정의서 ver1.8). serviceSeq/pgmSeq = ERP Method 라우팅·권한 판단 키.
        if (ep.serviceSeq() != null) root.put("serviceSeq", ep.serviceSeq());
        root.put("methodSeq", ep.methodSeq() != null ? ep.methodSeq() : 1);
        root.put("userSeq", ep.userSeq() != null ? ep.userSeq() : erp.getUserSeq());
        if (ep.pgmSeq() != null) root.put("pgmSeq", ep.pgmSeq());
        root.put("isTransaction", 1);

        // DataBlock1 = 영림원 표준 envelope 필드 + 화면 조회조건 병합 (거래처 샘플 구조)
        Map<String, Object> block = new LinkedHashMap<>();
        block.put("WorkingTag", "A");
        block.put("IDX_NO", 1);
        block.put("Status", "0");
        block.put("DataSeq", 1);
        block.put("Selected", 1);
        block.put("TABLE_NAME", "DataBlock1");
        block.put("UserName", "");
        if (dataBlock != null) block.putAll(dataBlock);
        Map<String, Object> innerRoot = new LinkedHashMap<>();
        innerRoot.put("DataBlock1", List.of(block));
        Map<String, Object> data = new LinkedHashMap<>();
        data.put("ROOT", innerRoot);
        root.put("data", data);

        Map<String, Object> envelope = new LinkedHashMap<>();
        envelope.put("ROOT", root);
        try {
            return om.writeValueAsString(envelope);
        } catch (Exception e) {
            throw new RuntimeException("ERP 요청 직렬화 실패", e);
        }
    }

    /** 로그용: 인증정보(certId/certKey/dsnOper/dsnBis) 값 마스킹 */
    private static String maskSecrets(String body, IfProperties.Erp erp) {
        if (body == null) return null;
        String s = body;
        for (String v : new String[]{erp.getCertId(), erp.getCertKey(), erp.getDsnOper(), erp.getDsnBis()}) {
            if (v != null && !v.isBlank()) s = s.replace(v, "***");
        }
        return s;
    }
}
