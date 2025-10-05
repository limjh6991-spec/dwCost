package com.dowinsys.cost.common.auth;

import java.time.LocalDateTime;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class UserInfo {
	private String userId;          // USER_ID
    private String userName;        // user_name
    private String password;        // password
    private String deptName;        // dept_name
    private String deptCode;        // dept_code
    private String positionName;    // position_name
    private String positionCode;    // position_code
    private String utg;             // UTG
    private String itg;             // ITG
    private LocalDateTime initDt;   // INIT_DT
    private String initUser;        // INIT_USER
    private LocalDateTime modiDt;   // MODI_DT
    private String modiUser;        // MODI_USER
    private String delYn;           // DEL_YN (default: 'N')
}
