package com.dowinsys.cost.component;

import java.util.Date;

import javax.crypto.SecretKey;

import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.stereotype.Component;

import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.SignatureAlgorithm;
import io.jsonwebtoken.security.Keys;

@Component
public class JwtUtil {
	public static final SecretKey SECRET_KEY = Keys.secretKeyFor(SignatureAlgorithm.HS256);

    public String generateToken(String userId) {
        String jwt = Jwts.builder()
                .setSubject(userId)
                .setIssuedAt(new Date())
                .setExpiration(new Date(System.currentTimeMillis() + 1000 * 60 * 60 * 10))	//현재시간 + 10시간
                .signWith(SECRET_KEY, SignatureAlgorithm.HS256)
                .compact();
        return jwt;
    }
    
    // JWT 유효성 검사
    public boolean validateToken(String token) {
        //extractUsername(token);	//userId
        return !isTokenExpired(token);
    }
    
    // JWT 토큰에서 정보 추출
    public String extractUsername(String token) {
        return Jwts.parserBuilder()
                .setSigningKey(SECRET_KEY)
                .build()
                .parseClaimsJws(token)
                .getBody()
                .getSubject();
    }
    
    // 토큰 만료 여부 확인
    private boolean isTokenExpired(String token) {
        Date expiration = Jwts.parserBuilder()
                .setSigningKey(SECRET_KEY)
                .build()
                .parseClaimsJws(token)
                .getBody()
                .getExpiration();
        return expiration.before(new Date());
    }   
    
    public String getUserId() {
    	// SecurityContext에서 Authentication 가져오기
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();

        if(authentication == null || !(authentication.getPrincipal() instanceof Jwt)){
            throw new IllegalStateException("JWT 토큰이 유효하지 않습니다.");
        }

        // Jwt 객체 가져오기
        Jwt jwt = (Jwt) authentication.getPrincipal();

        // JWT Claims에서 "sub" (userId) 추출
        return jwt.getSubject();
    }
}
