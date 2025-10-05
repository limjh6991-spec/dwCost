package com.dowinsys.cost.common.auth;

import java.util.List;
import java.util.Map;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class UserAuthInfo {
	String token;

	UserInfo userInfo;
	
//	List<UserRole> roleList;
	List<String> roleList;
	
	//사용자가 가지고 있는 권한 있는 시스템 리소스 Object
	SysResource sysResource;
	
	//사용자가 가지고 있는 권한 있는 시스템 리소스 리스트
	List<SysResource> sysResourceList;
	
	//제품유형 리스트(추후 권한있는거만 가져와야 할 수 있음)
	List<Map<String, Object>> prodCtgList;
	
	//작업현황 권한 있는지 확인
	String hasWorkStatusRoleYn;
}
