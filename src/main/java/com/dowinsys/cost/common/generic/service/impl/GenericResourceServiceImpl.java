package com.dowinsys.cost.common.generic.service.impl;

import java.util.List;
import java.util.Map;

import org.apache.ibatis.session.SqlSession;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.dowinsys.cost.common.enums.MapperEnum;
import com.dowinsys.cost.common.generic.service.GenericResourceService;
import com.dowinsys.cost.common.generic.vo.GenericResourceVo;
import com.dowinsys.cost.common.generic.vo.QueryData;
import com.dowinsys.cost.component.JwtUtil;

@Service("com.dowinsys.cost.common.generic.service.GenericResourceService")
public class GenericResourceServiceImpl implements GenericResourceService {
	
	@Autowired
    private SqlSession sqlSession;
	
	@Autowired
	JwtUtil jwUtil;
	
	@Override
	public List<Map<String, Object>> search(GenericResourceVo grv) {
		
		String queryId = grv.getQueryId();
		String menuId = grv.getMenuId();
		if(queryId == null || queryId.trim().isEmpty()) {
	        throw new IllegalArgumentException("'queryId' is missing or empty.");
	    }else if(menuId == null) {
        	throw new IllegalArgumentException("'menuId' is missing or empty.");
        }
		/**
		 * 조회시 권한이 필요하면 추가해야함!!!
	        if(!권한) {
	        	throw new AuthorizationException("You do not have permission to access this resource.");        	
	        }
		 */

		String mapperId = MapperEnum.getMapperNameByCode(menuId);		
        if(mapperId == null) {
        	throw new IllegalArgumentException("Failed to retrieve mapper ID: No mapper found for menu ID '" + menuId + "'.");
        }
        System.out.println(""+(new StringBuilder().append(mapperId).append(queryId)).toString());
		return sqlSession.selectList((new StringBuilder().append(mapperId).append(queryId)).toString(), grv.getQueryParams());        
	}
	
	@Transactional
	@Override
	public void saveData(GenericResourceVo grv) {
		
		String menuId = grv.getMenuId();
	    if(menuId == null) {
        	throw new IllegalArgumentException("'menuId' is missing or empty.");
        }
	    String mapperId = MapperEnum.getMapperNameByCode(menuId);		
        if(mapperId == null) {
        	throw new IllegalArgumentException("Failed to retrieve mapper ID: No mapper found for menu ID '" + menuId + "'.");
        }
        /**
		 * 저장시 권한이 필요하면 추가해야함!!!
	        if(!권한) {
	        	throw new AuthorizationException("You do not have permission to access this resource.");        	
	        }
		 */
		String userId = jwUtil.getUserId();
		try {
            if (grv.getDelete() != null) {
                for (QueryData deleteData : grv.getDelete()) {
                	if(deleteData.getQueryId() != null && !deleteData.getQueryId().trim().isEmpty() && !deleteData.getData().isEmpty()) {
                		for (Map<String, Object> data : deleteData.getData()) {
                			data.put("dowInsysUserId",userId);
                			sqlSession.delete((new StringBuilder().append(mapperId).append(deleteData.getQueryId())).toString(), data);
                		}
                	}
                }
            }

            if (grv.getInsert() != null) {
                for (QueryData insertData : grv.getInsert()) {
                	if(insertData.getQueryId() != null && !insertData.getQueryId().trim().isEmpty() && !insertData.getData().isEmpty()) {
                		for (Map<String, Object> data : insertData.getData()) {
                			data.put("dowInsysUserId",userId);
                			sqlSession.insert((new StringBuilder().append(mapperId).append(insertData.getQueryId())).toString(), data);                		
                		}
                	}
                }
            }

            if (grv.getUpdate() != null) {
                for (QueryData updateData : grv.getUpdate()) {
                	if(updateData.getQueryId() != null && !updateData.getQueryId().trim().isEmpty() && !updateData.getData().isEmpty()) {
                		for (Map<String, Object> data : updateData.getData()) {
                			data.put("dowInsysUserId",userId);
                			sqlSession.update((new StringBuilder().append(mapperId).append(updateData.getQueryId())).toString(), data);                		
                		}
                	}
                }
            }
        } catch (Exception e) {
            throw new RuntimeException("An error occurred while saving the data. Rolling back the transaction.", e);
        }
    }
}
