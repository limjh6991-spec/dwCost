/**
*	기준정보 > 사용자-메뉴 권한 관리
*/
package com.dowinsys.cost.web.m0006000.service.impl;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.dowinsys.cost.common.auth.SysResource;
import com.dowinsys.cost.component.JwtUtil;
import com.dowinsys.cost.web.m0006000.mapper.M0006009Mapper;
import com.dowinsys.cost.web.m0006000.service.M0006009Service;

@Service("com.dowinsys.cost.web.m0006000.service.M0006009")
public class M0006009ServiceImpl implements M0006009Service {

	@Autowired
	M0006009Mapper mapper;
	
	@Autowired
	JwtUtil jwtUtil;
	
	@Override
	public SysResource getRoleMenuTabList(Map<String,Object> params) {
		List<SysResource> sysRescList = mapper.selectRoleMenuTabList(params);
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
		
		return root;
	}

	@Override
	public void roleMenuTabSave(Map<String, Object> params) {
		String userId = jwtUtil.getUserId();
		List<Map<String, Object>> roleMenuList = (List<Map<String, Object>>)params.get("roleMenuList");
		
		Map<String, Object> delParam = new HashMap<String,Object>();
		delParam.put("roleId", params.get("roleId"));
		delParam.put("prodCategory", params.get("prodCategory"));
		//전체 삭제 후 저장
		mapper.deleteRoleSysResc(delParam);
		roleMenuList.forEach(roleMenu ->{
			roleMenu.put("userId", userId);
			mapper.insertRoleSysResc(roleMenu);
		});
	}

	@Override
	public void roleUserSave(Map<String, Object> params) {
		List<String> userIds = (List<String>)params.get("userIds");
		String roleId = (String)params.get("roleId");
		String roleName = (String)params.get("roleName");
		String initUser = jwtUtil.getUserId();
		Map<String, Object> roleUser = new HashMap<String,Object>();
		userIds.forEach(userId ->{
			roleUser.put("userId", userId);
			roleUser.put("roleId", roleId);
			roleUser.put("roleName", roleName);
			roleUser.put("initUser", initUser);
			mapper.insertUserRole(roleUser);
		});
	}

	@Override
	public void roleUserDelete(Map<String, Object> params) {
		List<String> userIds = (List<String>)params.get("userIds");
		String roleId = (String)params.get("roleId");
		Map<String, Object> roleUser = new HashMap<String,Object>();
		userIds.forEach(userId ->{
			roleUser.put("userId", userId);
			roleUser.put("roleId", roleId);
			mapper.deleteUserRole(roleUser);
		});
	}
	
	@Override
	public void roleDelete(Map<String, Object> params) {
		List<String> roleIds = (List<String>)params.get("roleIds");		
		Map<String, Object> role = new HashMap<String,Object>();
		String userId = jwtUtil.getUserId();
		roleIds.forEach(roleId ->{
			role.put("roleId", roleId);
			role.put("userId", userId);
			mapper.deleteRole(role);
		});
	}

	@Override
	@Transactional
	public String roleSave(Map<String, Object> params) {
		String rtnStr = "OK";
		String tempStr = "";
		String userId = jwtUtil.getUserId();
		
		List<Map<String,Object>> il = (List<Map<String,Object>>)params.get("insertList");
		List<Map<String,Object>> ul = (List<Map<String,Object>>)params.get("updateList");
		
		if(!il.isEmpty()) {
			for(Map<String,Object> role : il) {
				tempStr = mapper.checkRoleId(role);
				if(!"OK".equals(tempStr)) {
					return tempStr;
				}
				role.put("userId", userId);
				mapper.insertRole(role);
			}
		}
		
		if(!ul.isEmpty()) {
			for(Map<String,Object> role : ul) {
				role.put("userId", userId);
				mapper.updateRole(role);
			}
		}

		return rtnStr;
	}
}
