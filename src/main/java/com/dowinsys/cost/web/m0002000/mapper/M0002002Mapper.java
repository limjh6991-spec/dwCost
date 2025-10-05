/**
*	프로세스 플래닝 > 제품 모델 관리
*/
package com.dowinsys.cost.web.m0002000.mapper;

import org.apache.ibatis.annotations.Mapper;
import org.springframework.stereotype.Repository;

import com.dowinsys.cost.common.CamelMap;
import com.dowinsys.cost.common.generic.vo.GenericResourceVo;

import java.util.HashMap;
import java.util.List;
import java.util.Map;


@Repository("com.dowinsys.cost.web.m0002000.mapper.M0002002Mapper")
@Mapper
public interface M0002002Mapper {
	
	List<CamelMap<String, Object>> selectModelList();
	List<CamelMap<String, Object>> selectProductList();
	
	List<Map<String, Object>> checkDeleteModel(List<Map<String, Object>> vo);	
	List<Map<String, Object>> checkInsertModel(List<Map<String, Object>> vo);
	List<Map<String, Object>> checkInsertModelCode(List<Map<String, Object>> vo);
	List<Map<String, Object>> checkDeleteProduct(List<Map<String, Object>> vo);
	List<Map<String, Object>> checkInsertProduct(List<Map<String, Object>> vo);
	
	void uploadFilmImage(Map<String, Object> imageInfo);
}
