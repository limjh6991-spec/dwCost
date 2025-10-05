/**
*	프로세스 플래닝 > 제품 모델 관리
*/
package com.dowinsys.cost.web.m0002000.service;

import java.util.List;
import java.util.Map;

import org.springframework.web.multipart.MultipartFile;

import com.dowinsys.cost.common.CamelMap;
import com.dowinsys.cost.common.generic.vo.GenericResourceVo;

public interface M0002002Service {
	
	List<CamelMap<String, Object>> getModelList();
	List<CamelMap<String, Object>> getProductList();
	
	Map<String, Object> saveModelData(GenericResourceVo vo);		
	Map<String, Object> saveProductData(GenericResourceVo vo);
	
	void uploadFilmImage(MultipartFile image, Map<String, Object> imageInfo);
}
