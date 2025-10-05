package com.dowinsys.cost.config;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Profile;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

import com.dowinsys.cost.component.MenuLoggingInterceptor;

@Profile("!local")
@Configuration
public class WebMvcConfig implements WebMvcConfigurer {
	
	@Autowired
    MenuLoggingInterceptor menuLoggingInterceptor;
	
	@Override
    public void addInterceptors(InterceptorRegistry registry) {
        registry.addInterceptor(menuLoggingInterceptor).addPathPatterns("/api/**");
                
    }
}
