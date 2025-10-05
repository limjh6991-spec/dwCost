package com.dowinsys.cost.common.auth.service.impl;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.dowinsys.cost.common.auth.LoginReq;
import com.dowinsys.cost.common.auth.SysResource;
import com.dowinsys.cost.common.auth.UserAuthInfo;
import com.dowinsys.cost.common.auth.UserInfo;
import com.dowinsys.cost.common.auth.mapper.AuthMapper;
import com.dowinsys.cost.common.auth.service.AuthService;
import com.dowinsys.cost.component.JwtUtil;

@Service
public class AuthServiceImpl implements AuthService {
	
	// Logger 인스턴스 생성
    private static final Logger logger = LoggerFactory.getLogger(AuthServiceImpl.class);
    
	@Autowired
	AuthMapper mapper;
	
	private final JwtUtil jwtUtil;
  
    public AuthServiceImpl(JwtUtil jwtUtil) {
        this.jwtUtil = jwtUtil;
    }
    
	@Override
	public UserAuthInfo login(LoginReq loginReq) {
		//사용자 정보 확인
		UserInfo ui = mapper.selectCheckUser(loginReq);
		if(ui == null) {
			//사용자 정보 없음
			logger.warn("사용자 정보 없음 ID:::"+loginReq.getUserId());
			return null;
		}
		List<Map<String, Object>> prodCtgs = mapper.selectProdCtgByUser(loginReq);
		
		loginReq.setProdCategory(""+prodCtgs.get(0).get("prodCategory"));
		UserAuthInfo uai =  getAuthMenuTab(loginReq);	//권한있는 시스템리소스(메뉴Tab)
		
		uai.setRoleList(mapper.selectUserRoleList(loginReq));
		uai.setToken(jwtUtil.generateToken(loginReq.getUserId()));	//토큰 셋
		uai.setUserInfo(ui);	//사용자정보 셋
		uai.setProdCtgList(prodCtgs);
		uai.setHasWorkStatusRoleYn(mapper.selectHasWorkStatusYn(loginReq));
		
		return uai;
	}

	@Override
	public boolean validateToken(String token) {
		token = token.substring(7); // "Bearer " 이후의 부분만 가져옴
		return jwtUtil.validateToken(token);
	}
	
	@Override
	public UserAuthInfo getAuthMenuTab(LoginReq loginReq) {
		if(loginReq.getUserId() == null) {
			loginReq.setUserId(jwtUtil.getUserId());
		}
		
		List<SysResource> sysRescList = mapper.selectAuthMenuTabList(loginReq);
		SysResource root = new SysResource();
		root.setSysResourceId("ROOT_MENU");
		root.setChildSysResc(new ArrayList<SysResource>());
		
		SysResource lv1SysResc = null;
		SysResource lv2SysResc = null;
		SysResource lv3SysResc = null;
		
		for(SysResource sr : sysRescList) {
			if(sr.getLevel() == 1) {
				lv1SysResc = sr;
				lv1SysResc.setChildSysResc(new ArrayList<SysResource>());
				root.getChildSysResc().add(lv1SysResc);
			}else if(sr.getLevel() == 2) {
				lv2SysResc = sr;
				lv2SysResc.setChildSysResc(new ArrayList<SysResource>());
				lv1SysResc.getChildSysResc().add(sr);
			}else if(sr.getLevel() == 3) {
				lv3SysResc = sr;
				lv3SysResc.setChildSysResc(new ArrayList<SysResource>());
				lv2SysResc.getChildSysResc().add(sr);
			}else if(sr.getLevel() == 4) {
				lv3SysResc.getChildSysResc().add(sr);
			}
		}
		
		UserAuthInfo uai = new UserAuthInfo();
		uai.setSysResource(root);
		uai.setSysResourceList(sysRescList);
		return uai;
	}

	@Override
	public String changePw(Map<String, Object> params) {
		String rtnStr = "OK";
		String userId = params.get("userId").toString();
		String curPw = params.get("currentPassword").toString();
		String newPw = params.get("newPassword").toString();
		String cfPw = params.get("confirmPassword").toString();
		
		if(userId.isEmpty()) {
			rtnStr = "사용자 ID를 입력해주세요";
		}else if(curPw.isEmpty()) {
			rtnStr = "현재 비밀번호를 입력해주세요";
		}else if(newPw.isEmpty()) {
			rtnStr = "새로운 비밀번호를 입력해주세요";
		}else if(cfPw.isEmpty()) {
			rtnStr = "새로운 비밀번호 확인을 입력해주세요";
		}else if(!newPw.equals(cfPw)){
			rtnStr = "새 비밀번호와 확인이 일치하지 않습니다.";
		}else {
			String oldPw = mapper.selectPwByUserId(params);
			if(oldPw == null) {
				rtnStr = "사용자ID 정보가 없습니다.";
			}else {
				if(!oldPw.equals(curPw)) {
					rtnStr = "잘못된 현재 비밀번호입니다.";
				}else {
					mapper.updateUserPw(params);
				}
			}
		}
		
		return rtnStr;
	}
}
