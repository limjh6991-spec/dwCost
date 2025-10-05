package com.dowinsys.cost.common.auth.service;

import java.util.Map;

import com.dowinsys.cost.common.auth.LoginReq;
import com.dowinsys.cost.common.auth.UserAuthInfo;

public interface AuthService {
	UserAuthInfo login(LoginReq loginReq);
	
	boolean validateToken(String token);
	
	UserAuthInfo getAuthMenuTab(LoginReq loginReq);
	
	String changePw(Map<String, Object> params);
}
