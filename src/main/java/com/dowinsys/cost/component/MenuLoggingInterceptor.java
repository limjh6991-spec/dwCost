package com.dowinsys.cost.component;



import java.net.URLDecoder;
import java.nio.charset.StandardCharsets;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;

import com.dowinsys.cost.common.log.mapper.LogMapper;
import com.dowinsys.cost.common.log.vo.SysLog;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

@Profile("!local")
@Component
public class MenuLoggingInterceptor implements HandlerInterceptor {
	
	@Autowired
	JwtUtil jwtUtil;
	
	@Value("${spring.application.name}")
	private String appNm;
	
	@Autowired
	LogMapper logMapper;
	
	@Override
	public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) {
		try {
			String menuPath = getDecodeValue(request.getHeader("X-Menu-Path"));
			String menuUrl = getDecodeValue(request.getHeader("X-Menu-Url"));
			String tabPath = getDecodeValue(request.getHeader("X-Tab-Path"));
			String tabId = getDecodeValue(request.getHeader("X-Tab-Id"));
			String prod = getDecodeValue(request.getHeader("X-Prod"));
			String menuId = getDecodeValue(request.getHeader("X-Menu-Id"));
			String queryId = getDecodeValue(request.getHeader("X-Query-Id"));
			String dateTimeStr = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMddHHmmss"));
			String requestURI = request.getRequestURI();
			String userId = "NOT_LOGIN";
			String ip = request.getRemoteAddr();
	
			try {
				userId = jwtUtil.getUserId();
			}catch(IllegalStateException e) {
				//로그인되어 있지 않음
			}
			
			SysLog sysLog = new SysLog();
			sysLog.setAppNm(appNm);
			sysLog.setUserId(userId);
			sysLog.setProd(prod);
			sysLog.setMenuPath(menuPath);
			sysLog.setMenuUrl(menuUrl);
			sysLog.setTabPath(tabPath);
			sysLog.setTabId(tabId);
			sysLog.setRequestUri(requestURI);
			sysLog.setMenuId(menuId);
			sysLog.setQueryId(queryId);
			sysLog.setIp(ip);
			sysLog.setDateTimeStr(dateTimeStr);	

			logMapper.insertSysLog(sysLog);
		
//			System.out.println("appNm:::"+appNm);
//			System.out.println("userId:::"+userId);
//			System.out.println("prod:::"+prod);
//			System.out.println("menuPath:::"+menuPath);
//			System.out.println("menuUrl:::"+menuUrl);
//			System.out.println("tabPath:::"+tabPath);
//			System.out.println("tabId:::"+tabId);
//			System.out.println("requestURI:::"+requestURI);
//			System.out.println("menuId:::"+menuId);
//			System.out.println("queryId:::"+queryId);
//			System.out.println("ip:::"+ip);
//			System.out.println("dateTimeStr:::"+dateTimeStr);
		}catch(Exception e) {
			System.out.println("Failed to write system log");
			e.getStackTrace();
		}

		return true;
	}
	
	private String getDecodeValue(String value) {
		if(value != null) {
			return URLDecoder.decode(value,StandardCharsets.UTF_8);
		}
		
		return null;
	}
}
