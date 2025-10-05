package com.dowinsys.cost.common.auth;

import java.util.List;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class SysResource {
	String prodCategory;
	String sysResourceId;
	String upperSysResourceId;
	String description;
	String fullPath;
	String sysResourceName;
	int seq;
	int level;
	String sysResourceTypeCodeId;
	String fullSeq;
	String url;
	String hasAuth;
	String orgSysResourceId;
	List<SysResource> childSysResc;
}
