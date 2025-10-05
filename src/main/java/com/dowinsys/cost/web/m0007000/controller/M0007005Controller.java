/**
 * 카세트 관리 > 카세트 마스터
 */
package com.dowinsys.cost.web.m0007000.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import com.dowinsys.cost.web.m0007000.service.M0007005Service;

@RestController("com.dowinsys.cost.web.m0007000.controller.M0007005Controller")
@RequestMapping("/api/m0007000/m0007005")
public class M0007005Controller {

    @Autowired
    M0007005Service service;

    @PostMapping("/upload")
    public ResponseEntity<String> uploadFile(
            @RequestParam("file") MultipartFile file,
            @RequestParam("headers") String headers
    ) {
        if (file.isEmpty()) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("File is empty");
        }
        try {
            //TODO::duplication error
            String ret = service.uploadExcel(file, headers);
            return ResponseEntity.ok(ret);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("File upload failed");
        }
    }
}
