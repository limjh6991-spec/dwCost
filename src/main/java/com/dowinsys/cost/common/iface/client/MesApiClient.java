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
import org.springframework.web.util.UriComponentsBuilder;

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
        String base = mes.baseUrlFor(endpoint.site());   // HQ→hqBaseUrl, VN→baseUrl (없으면 baseUrl 폴백)
        if (base == null || base.isBlank()) {
            throw new IllegalStateException(
                    "iface.mes." + ("HQ".equals(endpoint.site()) ? "hq-base-url" : "base-url") + " 미설정");
        }

        // GET + query string (예: PRODUCT_SPEC_HQ /api/mes/product-spec?models=...) — 요청 바디 없음
        if (endpoint.mesQuery()) {
            String url = base + endpoint.path() + buildQueryString(params);
            ResponseEntity<String> res = rest.getForEntity(url, String.class);
            return res.getBody();
        }

        // 기존 POST + JSON body (WIP_SUBUL / FG_SUBUL) — 무변경
        String url = base + endpoint.path();
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

    /**
     * params → "?k=v&k2=v2" (null/빈값 스킵, URL 인코딩).
     *  - "site" 는 엔드포인트 라우팅용 내부값이므로 쿼리에서 제외.
     *  - 파라미터가 없으면 "" 반환(예: 면적기준 전체조회 = /api/mes/product-spec).
     */
    private String buildQueryString(Map<String, Object> params) {
        if (params == null || params.isEmpty()) return "";
        UriComponentsBuilder b = UriComponentsBuilder.newInstance();
        boolean any = false;
        for (Map.Entry<String, Object> e : params.entrySet()) {
            if ("site".equals(e.getKey())) continue;   // site 는 라우팅용 내부값 → 쿼리 제외
            Object v = e.getValue();
            if (v == null) continue;
            if (v instanceof java.util.Collection<?> col) {          // 배열/리스트 → k=v1&k=v2 로 전개(단일 Object 취급 방지)
                for (Object it : col) {
                    if (it != null && !String.valueOf(it).isBlank()) { b.queryParam(e.getKey(), it); any = true; }
                }
                continue;
            }
            if (String.valueOf(v).isBlank()) continue;
            b.queryParam(e.getKey(), v);
            any = true;
        }
        return any ? b.build().encode().toUriString() : "";
    }
}
