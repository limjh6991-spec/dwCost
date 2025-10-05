package com.dowinsys.cost.common.print;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.io.OutputStream;
import java.io.IOException;
import java.net.Socket;
import java.util.List;

@RestController
@RequestMapping("/api/print")
public class PrintController {

    // 프린터의 IP와 포트 설정 (예: 172.30.1.26:9100)
    //private static final String PRINTER_IP = "172.30.1.26";
    //private static final int PRINTER_PORT = 9100;

    @PostMapping("/printZpl")
    public ResponseEntity<String> printZPL(@RequestBody PrintVo request) {
        
        List<String> zplList = request.getZplList();
        String printerIp = request.getPrinterIp();
        int printPort = request.getPrinterPort();
        try (Socket socket = new Socket(printerIp, printPort);
             OutputStream outputStream = socket.getOutputStream()) {

        	zplList.forEach(zpl->{
        		try {
        			// ZPL 코드를 바이트 배열로 변환 후 전송
					outputStream.write(zpl.getBytes());
					outputStream.flush();
				} catch (IOException e) {
					// TODO Auto-generated catch block
					e.printStackTrace();
				}
        	});
            return ResponseEntity.ok("Printed successfully");
        } catch (IOException e) {
            e.printStackTrace();
            return ResponseEntity.status(500).body("Error printing: " + e.getMessage());
        }
    }
}
