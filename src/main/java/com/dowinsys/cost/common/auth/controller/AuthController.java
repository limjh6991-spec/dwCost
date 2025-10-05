package com.dowinsys.cost.common.auth.controller;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Map;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.dowinsys.cost.common.auth.LoginReq;
import com.dowinsys.cost.common.auth.UserAuthInfo;
import com.dowinsys.cost.common.auth.service.AuthService;

@RestController
@RequestMapping("/api/auth")
public class AuthController {
	// Logger 인스턴스 생성
    private static final Logger logger = LoggerFactory.getLogger(AuthController.class);
    
    @Autowired
    AuthService service;
    
    @PostMapping("/login")
    public ResponseEntity<UserAuthInfo>  login(@RequestBody LoginReq lq) {
    	return ResponseEntity.ok(service.login(lq)); 
    }

    @PostMapping("/verify")
    public ResponseEntity<Boolean> validateToken(@RequestHeader("Authorization") String token) {
    	return ResponseEntity.ok(service.validateToken(token)); 
    }
    
    
    @PostMapping("/logout")
    public ResponseEntity<String> logout(@RequestHeader("Authorization") String token) {
        //todo 
        //token 관련 로직이 필요 할 수 있음
        

        return ResponseEntity.ok("Logged out successfully");
    }
    
    @PostMapping("/changepw")
    public ResponseEntity<String> changePw(@RequestBody Map<String, Object> params) {
        return ResponseEntity.ok(service.changePw(params));
    }
    
    @GetMapping("/current-time")
    public String getCurrentTime() {
        LocalDateTime now = LocalDateTime.now();
        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy.MM.dd HH:mm");
        return now.format(formatter);
    }
    
    @PostMapping("/change-prodctg")
    public ResponseEntity<UserAuthInfo> changeProdCtg(@RequestBody LoginReq lq) {
    	return ResponseEntity.ok(service.getAuthMenuTab(lq)); 
    }
}
