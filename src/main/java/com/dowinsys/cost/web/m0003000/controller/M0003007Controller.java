/**
*	제조 실적 입력 > Lot Run Card 발행
*/
package com.dowinsys.cost.web.m0003000.controller;

import java.util.HashMap;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import com.dowinsys.cost.web.m0003000.service.M0003007Service;

@RestController("com.dowinsys.cost.web.m0003000.controller.M0003007Controller")
@RequestMapping("/api/m0003000/m0003007")
public class M0003007Controller {

	@Autowired
	M0003007Service service;
	
    @PostMapping("/getFilmImage")
    public ResponseEntity<?> getFilmImage(@RequestBody Map<String, String> request) {
        try {
            // ClassPath에서 엑셀 파일 로드\
        	Map<String, Object> obj = service.getFilmImage(request);
        	byte[] imageData = (byte[]) obj.get("imageData");

            // 파일이 존재하지 않으면 404 반환
            if (imageData.length==0) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).body(null);
            }

            // HTTP 응답 생성
            return ResponseEntity.ok()
                    .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=film.jpg")
                    .header(HttpHeaders.CONTENT_TYPE, "image/jpeg")
                    .body(imageData);

        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(("필름 이미지 다운로드 실패: " + e.getMessage()).getBytes());
        }
    }
}
