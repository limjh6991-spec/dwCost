/**
*	프로세스 플래닝 > 제품 모델 관리
*/
package com.dowinsys.cost.web.m0002000.service.impl;

import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import com.dowinsys.cost.common.CamelMap;
import com.dowinsys.cost.common.generic.service.GenericResourceService;
import com.dowinsys.cost.common.generic.vo.GenericResourceVo;
import com.dowinsys.cost.common.generic.vo.QueryData;
import com.dowinsys.cost.web.m0002000.mapper.M0002002Mapper;
import com.dowinsys.cost.web.m0002000.service.M0002002Service;

@Service("com.dowinsys.cost.web.m0002000.service.M0002002")
public class M0002002ServiceImpl implements M0002002Service {

	@Autowired
	M0002002Mapper mapper;
	
	@Autowired
	GenericResourceService genericService;
	
	public List<CamelMap<String, Object>> getModelList() {
		List<CamelMap<String, Object>> dt =  mapper.selectModelList();		
		return dt;
	}
	
	public Map<String, Object> saveModelData(GenericResourceVo grv) {
		
		Map<String, Object> resultData = new HashMap<>();
		
		// Check if the item can be deleted 
		try
		{
			List<Map<String, Object>> checkData;
			
			// 삭제 불가한게 있는지 check						
			if ( grv.getDelete() != null ) {
				for (QueryData deleteData : grv.getDelete()) {
					
					if ( deleteData.getData() != null && !deleteData.getData().isEmpty()) {
						 checkData =  mapper.checkDeleteModel(deleteData.getData());
					
						if ( checkData != null && !checkData.isEmpty() && !"NoData".equals(checkData.get(0).get("model")) ) {
							
							resultData.put("resultCode", "CHECK_DELETE");
							resultData.put("resultData", checkData.get(0).get("model"));
							
							return resultData;
						}	
					}
				}
			}
			
			if ( grv.getInsert() != null ) {
				for (QueryData insertData : grv.getInsert()) {
					
					if ( insertData.getData() != null && !insertData.getData().isEmpty()) {
						
						 checkData =  mapper.checkInsertModel(insertData.getData());
					
						if ( checkData != null && !checkData.isEmpty() && !"NoData".equals(checkData.get(0).get("model")) ) {
							
							resultData.put("resultCode", "CHECK_INSERT");
							resultData.put("resultData", checkData.get(0).get("model"));
							
							return resultData;
						}
						
						checkData =  mapper.checkInsertModelCode(insertData.getData());
							
						if ( checkData != null && !checkData.isEmpty() && !"NoData".equals(checkData.get(0).get("code")) ) {
							
							resultData.put("resultCode", "CHECK_INSERT_CODE");
							resultData.put("resultData", checkData.get(0).get("code"));
							
							return resultData;
						}							
					}
				}
			}				
			
			if ( resultData.isEmpty() ) {
				// 정상 데이터 변경 저장 처리	
				genericService.saveData(grv);
				resultData.put("resultCode", "SUCCESS");
			}			
		}
		catch ( Exception e ) {
			throw new RuntimeException("saveData error", e);
		}
		
		return resultData;
	}		
	
	public List<CamelMap<String, Object>> getProductList() {
		List<CamelMap<String, Object>> dt =  mapper.selectProductList();		
		return dt;
	}
	
	public Map<String, Object> saveProductData(GenericResourceVo grv) {
		
		Map<String, Object> resultData = new HashMap<>();
		
		// Check if the item can be deleted 
		try
		{
			List<Map<String, Object>> checkData;
			
			// 삭제 불가한게 있는지 check					
			if ( grv.getDelete() != null ) {
				for (QueryData deleteData : grv.getDelete()) {
					
					if ( deleteData.getData() != null && !deleteData.getData().isEmpty()) {
						 checkData =  mapper.checkDeleteProduct(deleteData.getData());
					
						if ( checkData != null && !checkData.isEmpty() && !"NoData".equals(checkData.get(0).get("prodCode")) ) {
							
							resultData.put("resultCode", "CHECK_DELETE");
							resultData.put("resultData", checkData.get(0).get("prodCode"));
							
							return resultData;
						}	
					}
				}
			}
			
			if ( grv.getInsert() != null ) {
				for (QueryData insertData : grv.getInsert()) {
					
					if ( insertData.getData() != null && !insertData.getData().isEmpty()) {
						 checkData =  mapper.checkInsertProduct(insertData.getData());
					
						if ( checkData != null && !checkData.isEmpty() && !"NoData".equals(checkData.get(0).get("prodCode")) ) {
							
							resultData.put("resultCode", "CHECK_INSERT");
							resultData.put("resultData", checkData.get(0).get("prodCode"));
							
							return resultData;
						}	
					}
				}
			}
			
			if ( resultData.isEmpty() ) {
				// 정상 데이터 변경 저장 처리	
				genericService.saveData(grv);
				resultData.put("resultCode", "SUCCESS");
			}			
		}
		catch ( Exception e ) {
			throw new RuntimeException("saveData error", e);
		}
		
		return resultData;
	}
	
	@Override
	public void uploadFilmImage(MultipartFile image, Map<String, Object> imageInfo) {
		Map<String,Object> uploadObj = imageInfo;
		try {
			uploadObj.put("image",image.getBytes());
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}

		mapper.uploadFilmImage(imageInfo);
	};
}
