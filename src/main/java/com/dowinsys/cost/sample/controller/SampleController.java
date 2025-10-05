package com.dowinsys.cost.sample.controller;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.util.Arrays;
import java.util.Iterator;
import java.util.List;
import java.util.Map;

import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import com.dowinsys.cost.common.utils.ExcelUtils;

@RestController("com.dowinsys.cost.sample.controller.SampleController")
@RequestMapping("/api/sample")
public class SampleController {

	@PostMapping("/upload")
    public ResponseEntity<String> uploadFile(
    		@RequestParam("file") MultipartFile file,
    		@RequestParam("headers") String headers
    ) {
        if (file.isEmpty()) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("File is empty");
        }
        try {
        	List<String> headerList = Arrays.asList(headers.split(","));
        	List<Map<String, String>> list = ExcelUtils.readExcel(file, headerList, 0);        	
            return ResponseEntity.ok("File uploaded successfully");
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("File upload failed");
        }
    }
}
