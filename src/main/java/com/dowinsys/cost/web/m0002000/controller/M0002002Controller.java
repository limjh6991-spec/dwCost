/**
*	프로세스 플래닝 > 제품 모델 관리
*/
package com.dowinsys.cost.web.m0002000.controller;

import java.util.HashMap;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import com.dowinsys.cost.common.generic.vo.GenericResourceVo;
import com.dowinsys.cost.web.m0002000.service.M0002002Service;

@RestController("com.dowinsys.cost.web.m0002000.controller.M0002002Controller")
@RequestMapping("/api/m0002000/m0002002")
public class M0002002Controller {

	@Autowired
	M0002002Service service;
	
	@GetMapping("/getModelList")
	public ResponseEntity<?> getModelList() {
		return ResponseEntity.ok(service.getModelList());
	}
	
	@PostMapping("/saveModelData")
	public ResponseEntity<?> saveModelData(@RequestBody GenericResourceVo grv) {
		Map<String, Object> resultData = new HashMap<>();
		resultData = service.saveModelData(grv);
		return ResponseEntity.ok(resultData);
		
	}
	
	@PostMapping("/saveProductData")
	public ResponseEntity<?> saveProductData(@RequestBody GenericResourceVo grv) {
		Map<String, Object> resultData = new HashMap<>();
		resultData = service.saveProductData(grv);
		return ResponseEntity.ok(resultData);
		
	}
	
	@PostMapping("/uploadFilmImage")
    public ResponseEntity<?> uploadFilmImage(
            @RequestParam MultipartFile image,
            @RequestParam String model,
            @RequestParam String code
    		) {
        try {
        	Map<String,Object> imageInfo = new HashMap<String,Object>();
        	imageInfo.put("model", model);
        	imageInfo.put("code", code);
        	service.uploadFilmImage(image,imageInfo);
            return ResponseEntity.ok("이미지 업로드 성공");
        } catch (Exception e) {
            return ResponseEntity.status(500).body("이미지 업로드 실패: " + e.getMessage());
        }
    }
}
