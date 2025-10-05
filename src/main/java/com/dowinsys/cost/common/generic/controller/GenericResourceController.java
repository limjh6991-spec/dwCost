package com.dowinsys.cost.common.generic.controller;

import java.util.HashMap;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.dowinsys.cost.common.generic.service.GenericResourceService;
import com.dowinsys.cost.common.generic.vo.GenericResourceVo;

@RestController("com.dowinsys.cost.common.generic.controller.GenericResourceController")
@RequestMapping("/api/generic")
public class GenericResourceController {

	@Autowired
	GenericResourceService service;
	
	@PostMapping("/search")
    public ResponseEntity<?> search(@RequestBody GenericResourceVo grv) {
		try {
            return ResponseEntity.ok(service.search(grv));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                                 .body("An error occurred while fetching data: " + e.getMessage());
        }
    }
	
	@PostMapping("/saveData")
    public ResponseEntity<?> saveData(@RequestBody GenericResourceVo grv) {
		try {
			service.saveData(grv);
            Map<String, Object> response = new HashMap<String, Object>();
            response.put("status", "success");
            response.put("message", "Data saved successfully.");
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("status", "failure");
            response.put("message", "Data save failed: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(response);
        }
    }
}
