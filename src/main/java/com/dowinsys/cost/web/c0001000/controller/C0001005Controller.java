/**
 * 기준정보 > 제품기준정보
 */
package com.dowinsys.cost.web.c0001000.controller;

import com.dowinsys.cost.web.c0001000.service.C0001005Service;
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


@RestController("com.dowinsys.cost.web.c0001000.controller.C0001005Controller")
@RequestMapping("/api/c0001000/C0001005")
public class C0001005Controller {

    @Autowired
    C0001005Service service;

    @PostMapping("/upload")
    public ResponseEntity<String> uploadFile(
            @RequestParam("file") MultipartFile file,
            @RequestParam("headers") String headers
    ) {
        if (file.isEmpty()) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("File is empty");
        }
        try {
            Map<String, String> ret = service.uploadExcel(file, headers);
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
