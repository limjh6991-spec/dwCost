/**
 * 기준정보 > 원가기준정보
 */
package com.dowinsys.cost.web.c0001000.controller;

import com.dowinsys.cost.web.c0001000.service.C0001004Service;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.Map;
import java.util.Objects;


@RestController("com.dowinsys.cost.web.c0001000.controller.C0001004Controller")
@RequestMapping("/api/c0001000/c0001004")
public class C0001004Controller {

    @Autowired
    C0001004Service service;

    // Tab1
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
    
        @GetMapping("/tab1/carryOver")
    public Map<String, Object> tab1CarryOver(@RequestParam("yyyymm") String yyyymm,
                                             @RequestParam("prevYyyymm") String prevYyyymm,
                                             @RequestParam("site") String site) throws Exception {
        return service.tab1CarryOver(yyyymm, prevYyyymm, site);
    }


    // Tab2
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

        @GetMapping("/tab2/carryOver")
    public Map<String, Object> tab2CarryOver(@RequestParam("yyyymm") String yyyymm,
                                             @RequestParam("prevYyyymm") String prevYyyymm,
                                             @RequestParam("site") String site) throws Exception {
        return service.tab2CarryOver(yyyymm, prevYyyymm, site);
    }

    // Tab3
        @PostMapping("/tab3Upload")
    public ResponseEntity<String> tab3UploadFile(
            @RequestParam("file") MultipartFile file,
            @RequestParam("headers") String headers
    ) {
        if (file.isEmpty()) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("File is empty");
        }
        try {
            Map<String, String> ret = service.tab3UploadExcel(file, headers);
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
    
        @GetMapping("/tab3/carryOver")
    public Map<String, Object> tab3CarryOver(@RequestParam("yyyymm") String yyyymm,
                                             @RequestParam("prevYyyymm") String prevYyyymm,
                                             @RequestParam("site") String site) throws Exception {
        return service.tab3CarryOver(yyyymm, prevYyyymm, site);
    }


    // Tab5
        @PostMapping("/tab5Upload")
    public ResponseEntity<String> tab5UploadFile(
            @RequestParam("file") MultipartFile file,
            @RequestParam("headers") String headers
    ) {
        if (file.isEmpty()) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("File is empty");
        }
        try {
            Map<String, String> ret = service.tab5UploadExcel(file, headers);
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