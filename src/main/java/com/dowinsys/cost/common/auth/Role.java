package com.dowinsys.cost.common.auth;

import java.time.LocalDateTime;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class Role {
	String roleId;
	String roleName;
	String description;
	LocalDateTime initDt;
	String initUser;
	LocalDateTime modiDt;
	String modiUser;
}
