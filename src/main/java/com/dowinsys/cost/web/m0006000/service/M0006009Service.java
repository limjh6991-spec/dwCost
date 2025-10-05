/**
*	기준정보 > 사용자-메뉴 권한 관리
*/
package com.dowinsys.cost.web.m0006000.service;

import java.util.Map;

import com.dowinsys.cost.common.auth.SysResource;

public interface M0006009Service {
//	UserAuthInfo getMenuTab();
//	List<Role> getRoleList();
//	List<Map<String, Object>> getRoleUserList(Role role);
	SysResource getRoleMenuTabList(Map<String, Object> params);
	void roleMenuTabSave(Map<String, Object> params);
	void roleUserSave(Map<String, Object> params);
	void roleUserDelete(Map<String, Object> params);
	void roleDelete(Map<String, Object> params);
	String roleSave(Map<String, Object> params);
}
