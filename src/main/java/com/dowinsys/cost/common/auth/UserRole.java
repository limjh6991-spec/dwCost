package com.dowinsys.cost.common.auth;

import java.time.LocalDateTime;
import java.util.List;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class UserRole {
	String userId;          
    String roleId;          
    String description;     
    LocalDateTime initDt;   
    String initUser;        
    LocalDateTime modiDt;   
    String modiUser;
    
    //Role이 가지고 있는 시스템 리소스 리스트
    List<SysResource> sysResourceList;
}
