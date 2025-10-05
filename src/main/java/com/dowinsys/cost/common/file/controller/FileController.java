package com.dowinsys.cost.common.file.controller;

import java.io.File;
import java.io.IOException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import com.dowinsys.cost.common.file.service.FileService;
import com.dowinsys.cost.common.file.vo.FileVo;
import com.dowinsys.cost.common.utils.FileUtils;
import com.dowinsys.cost.component.JwtUtil;

import jakarta.annotation.PostConstruct;

@RestController("com.dowinsys.cost.common.file.controller.FileController")
@RequestMapping("/api/files")
public class FileController {

	@Autowired
	FileService service;
	
	@Autowired
	JwtUtil jwUtil;
	
	@Value("${file.upload.dir}")
	private String uploadDir;
	
	@PostConstruct
    public void init() {
        // 폴더 초기화
        File uploadDirFile = new File(uploadDir);
        if (!uploadDirFile.exists()) {
            uploadDirFile.mkdirs(); // 폴더 생성
        }        
    }
	
	@GetMapping("/readFiles/{groupId}")
    public ResponseEntity<List<FileVo>> readFiles(@PathVariable String groupId) {
        List<FileVo> files = service.getFilesByGroupId(groupId);
        return ResponseEntity.ok(files);
    }
	
	@PostMapping("/uploadFile")
    public ResponseEntity<List<FileVo>> uploadFiles(
    		@RequestParam("files") MultipartFile[] files,
    		@RequestParam("groupId") String groupId
    ) {
        List<FileVo> responses = new ArrayList<>();

        for (MultipartFile file : files) {
            String status;
            String uniqueFileName = null;
            try {
            	uniqueFileName = FileUtils.generateUniqueFileName();
            	Path filePath = FileUtils.generateFilePath(uploadDir, uniqueFileName);
            	
            	Files.createDirectories(filePath.getParent());
            	
                Files.write(filePath, file.getBytes());
                status = "Uploaded";
                FileVo vo = new FileVo();
                vo.setId(uniqueFileName);
                vo.setGroupId(groupId);
                vo.setFileName(file.getOriginalFilename());
                vo.setFileSize(String.valueOf(file.getSize()));
                vo.setFilePath(filePath.toString());
                vo.setCreatedBy(jwUtil.getUserId());
                
                service.insertFile(vo);
            } catch (IOException e) {
                status = "Error";
            }
            responses.add(new FileVo(uniqueFileName, file.getOriginalFilename(), status));
        }

        return ResponseEntity.ok(responses);
    }
	
	@PostMapping("/downloadFile/{fileId}")
    public ResponseEntity<?> downloadFile(@PathVariable String fileId) {
		try {
			FileVo fileEntity = service.readFile(fileId);
	        if (fileEntity == null) {
	            return ResponseEntity.notFound().build();
	        }

			Path filePath = Paths.get(fileEntity.getFilePath());
	        if (!Files.exists(filePath)) {
	            return ResponseEntity.notFound().build();
	        }

	        byte[] fileBytes = Files.readAllBytes(filePath);
	        
	        String encodedFileName = URLEncoder.encode(fileEntity.getFileName(), StandardCharsets.UTF_8.toString())
                    .replace("+", "%20"); // 공백 처리

	        return ResponseEntity.ok()
	                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename*=UTF-8''" + encodedFileName)
	                .header(HttpHeaders.CONTENT_TYPE, MediaType.APPLICATION_OCTET_STREAM_VALUE)
	                .header(HttpHeaders.CACHE_CONTROL, "no-cache, no-store, must-revalidate")
	                .header(HttpHeaders.PRAGMA, "no-cache")
	                .header(HttpHeaders.EXPIRES, "0")
	                .body(fileBytes);
	    } catch (IOException e) {
	        return ResponseEntity.internalServerError().body("파일 다운로드 실패: " + e.getMessage());
	    }
    }
	
	@DeleteMapping("/removeFile/{fileId}")
    public ResponseEntity<?> removeFile(@PathVariable String fileId) {
        try {
            // 파일 isDeleted 1로 업데이트
        	FileVo vo = new FileVo();
        	vo.setId(fileId);
        	vo.setDeletedBy(jwUtil.getUserId());
            service.removeFile(vo);
            return ResponseEntity.ok("파일이 성공적으로 삭제되었습니다.");
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.internalServerError().body("파일 삭제 실패: " + e.getMessage());
        }
    }
}
