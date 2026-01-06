/**
 * 타시스템 > 유상사급
 */
package com.dowinsys.cost.web.c0007000.controller;

import com.dowinsys.cost.web.c0007000.service.C0007007Service;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import java.util.Map;
import java.util.Objects;

@RestController("com.dowinsys.cost.web.c0007000.controller.C0007007Controller")
@RequestMapping("/api/c0007000/c0007007")
public class C0007007Controller {

    @Autowired
    C0007007Service service;

    @PostMapping("/tab1Upload")
    public ResponseEntity<String> tab1UploadFile(
            @RequestParam("file") MultipartFile file,
            @RequestParam("headers") String headers
    ) {
        if (file.isEmpty()) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("File is empty");
        }
        try {
            Map<String, String> ret = service.tab1UploadExcel(file, headers);
            if (Objects.equals(ret.get("status"), "success")) {
                return ResponseEntity.ok("File uploaded successfully");
            } else if (Objects.equals(ret.get("status"), "error") && !ret.get("errorMessage").isEmpty()) {
                return ResponseEntity.ok(ret.get("errorMessage"));
            } else {
                return ResponseEntity.ok("File upload failed");
            }

        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("File upload failed");
        }
    }

    @PostMapping("/tab2Upload")
    public ResponseEntity<String> tab2UploadFile(
            @RequestParam("file") MultipartFile file,
            @RequestParam("headers") String headers
    ) {
        if (file.isEmpty()) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("File is empty");
        }
        try {
            Map<String, String> ret = service.tab2UploadExcel(file, headers);
            if (Objects.equals(ret.get("status"), "success")) {
                return ResponseEntity.ok("File uploaded successfully");
            } else if (Objects.equals(ret.get("status"), "error") && !ret.get("errorMessage").isEmpty()) {
                return ResponseEntity.ok(ret.get("errorMessage"));
            } else {
                return ResponseEntity.ok("File upload failed");
            }

        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("File upload failed");
        }
    }
}
