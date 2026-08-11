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
        if (erp.getBaseUrl() == null || erp.getBaseUrl().isBlank()) {
            throw new IllegalStateException("iface.erp.base-url 미설정");
        }
        if (!props.isErpCertConfigured()) {
            throw new IllegalStateException(
                "ERP 인증정보(certId/certKey/dsnOper/dsnBis) 미설정 - 환경변수로 주입 필요");
        }

        String url = erp.getBaseUrl() + endpoint.path();
        String body = buildEnvelope(erp, dataBlock);

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        HttpEntity<String> req = new HttpEntity<>(body, headers);

        ResponseEntity<String> res = rest.postForEntity(url, req, String.class);
        return res.getBody();
    }

    /** 영림원 봉투 구성: { "ROOT": { cert..., "data": { "ROOT": { "DataBlock1": [dataBlock] } } } } */
    private String buildEnvelope(IfProperties.Erp erp, Map<String, Object> dataBlock) {
        Map<String, Object> root = new LinkedHashMap<>();
        root.put("certId", erp.getCertId());
        root.put("certKey", erp.getCertKey());
        root.put("dsnOper", erp.getDsnOper());
        root.put("dsnBis", erp.getDsnBis());
        root.put("companySeq", erp.getCompanySeq());
        root.put("languageSeq", erp.getLanguageSeq());
        root.put("securityType", 0);
        root.put("userId", "");
        root.put("methodSeq", 1);
        root.put("workingTag", "I");
        root.put("userSeq", erp.getUserSeq());
        root.put("isTransaction", 1);

        Map<String, Object> block = (dataBlock == null) ? new LinkedHashMap<>() : dataBlock;
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
}
