/**
 * 인터페이스 전용 RestTemplate 빈 (타임아웃 적용).
 */
package com.dowinsys.cost.common.iface.config;

import org.springframework.boot.web.client.RestTemplateBuilder;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.client.RestTemplate;

import java.time.Duration;

@Configuration
public class IfHttpConfig {

    @Bean(name = "ifRestTemplate")
    public RestTemplate ifRestTemplate(RestTemplateBuilder builder, IfProperties props) {
        return builder
                .setConnectTimeout(Duration.ofMillis(props.getConnectTimeoutMs()))
                .setReadTimeout(Duration.ofMillis(props.getReadTimeoutMs()))
                .build();
    }
}
