package com.dowinsys.cost.common.excel;

import java.util.Map;

import org.springframework.core.io.ClassPathResource;
import org.springframework.core.io.Resource;
import org.springframework.http.ContentDisposition;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/excel")
public class ExcelController {
	
    // Vue에서 /api/convert-pdf 로 POST
    @PostMapping("/getExcelTemplate")
    public ResponseEntity<?> getExcelTemplate(@RequestBody Map<String, String> request) {
        try {
            // ClassPath에서 엑셀 파일 로드
            Resource resource = new ClassPathResource(request.get("filePath"));

            // 파일이 존재하지 않으면 404 반환
            if (!resource.exists()) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).body(null);
            }

            // HTTP 응답 생성
            return ResponseEntity.ok()
                    .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=template.xlsx")
                    .header(HttpHeaders.CONTENT_TYPE, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
                    .body(resource);

        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(("엑셀 템플릿 다운로드 실패: " + e.getMessage()).getBytes());
        }
    }
    
    @PostMapping("/getFilmImage")
    public ResponseEntity<?> getFilmImage(@RequestBody Map<String, String> request) {
        try {
            // ClassPath에서 엑셀 파일 로드
            Resource resource = new ClassPathResource(request.get("filePath"));

            // 파일이 존재하지 않으면 404 반환
            if (!resource.exists()) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).body(null);
            }

            // HTTP 응답 생성
            return ResponseEntity.ok()
                    .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=film.jpg")
                    .header(HttpHeaders.CONTENT_TYPE, "image/jpeg")
                    .body(resource);

        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(("필름 이미지 다운로드 실패: " + e.getMessage()).getBytes());
        }
    }
}

