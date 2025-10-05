/**
*	기준정보 > 공정별 불량코드 등록
*/
package com.dowinsys.cost.web.m0006000.service.impl;

import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import com.dowinsys.cost.common.utils.ExcelUtils;
import com.dowinsys.cost.web.m0006000.mapper.M0006007Mapper;
import com.dowinsys.cost.web.m0006000.service.M0006007Service;

@Service("com.dowinsys.cost.web.m0006000.service.M0006007")
public class M0006007ServiceImpl implements M0006007Service {

	@Autowired
	M0006007Mapper mapper;
	
	@Override
	@Transactional
    public Map<String, Object> saveData(Map<String, Object> params) throws Exception {
		Map<String, Object> resultData = new HashMap<>();
		
		try {
			if(params.get("공정코드")== null) {
				resultData.put("resultCode", "CHECK PARAMS");
				return resultData;
			}
            mapper.deleteDataAll(params);
            List<Object> insertList = (List<Object>) params.get("insert");
            if(insertList.size()>0)
            	mapper.insertDataAll(params);
            resultData.put("resultCode", "SUCCESS");
        } catch (Exception e) {
            //TODO:delete
            e.printStackTrace();
            throw e;
        }
		
		return resultData;
    }
}
