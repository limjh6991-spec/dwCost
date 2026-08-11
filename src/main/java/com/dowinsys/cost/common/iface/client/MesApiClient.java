/**
 * 미라콤 EMI(MES) 호출 클라이언트.
 * 요청 = 단순 JSON({factory, workDate, matId}), 인증 불필요.
 * 응답 본문(JSON 문자열)을 그대로 반환 → 적재 프로시저가 $.data.rows 파싱.
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

import java.util.Map;

@Component
public class MesApiClient {

    private final RestTemplate rest;
    private final IfProperties props;
    private final ObjectMapper om = new ObjectMapper();

    public MesApiClient(@Qualifier("ifRestTemplate") RestTemplate rest, IfProperties props) {
        this.rest = rest;
        this.props = props;
    }

    public String call(IfEndpoint endpoint, Map<String, Object> params) {
        IfProperties.Mes mes = props.getMes();
        if (mes.getBaseUrl() == null || mes.getBaseUrl().isBlank()) {
            throw new IllegalStateException("iface.mes.base-url 미설정");
        }
        String url = mes.getBaseUrl() + endpoint.path();

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);

        String body;
        try {
            body = om.writeValueAsString(params == null ? Map.of() : params);
        } catch (Exception e) {
            throw new RuntimeException("MES 요청 직렬화 실패", e);
        }
        HttpEntity<String> req = new HttpEntity<>(body, headers);

        ResponseEntity<String> res = rest.postForEntity(url, req, String.class);
        return res.getBody();
    }
}
