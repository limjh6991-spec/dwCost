/**
 * 카세트 관리 > 카세트 불출
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

import com.dowinsys.cost.web.m0007000.service.M0007001Service;

import java.util.Map;
import java.util.Objects;

@RestController("com.dowinsys.cost.web.m0007000.controller.M0007001Controller")
@RequestMapping("/api/m0007000/m0007001")
public class M0007001Controller {

    @Autowired
    M0007001Service service;

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
            //TODO::check 세정 or 강화
            Map<String, String> ret = service.uploadExcel(file, headers);
            if(Objects.equals(ret.get("status"), "success")) {
                return ResponseEntity.ok("File uploaded successfully");
            } else if(Objects.equals(ret.get("status"), "error") && !ret.get("errorMessage").isEmpty()) {
                return ResponseEntity.ok(ret.get("errorMessage"));
            } else {
                return ResponseEntity.ok("File upload failed");
            }

        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("File upload failed");
        }
    }

}
