package com.dowinsys.cost.common.auth;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class LoginReq {
	String userId;
	String password; 
	String prodCategory;
}
