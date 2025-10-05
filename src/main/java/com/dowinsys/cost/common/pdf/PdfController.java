package com.dowinsys.cost.common.pdf;

import java.util.Map;

import org.springframework.http.ContentDisposition;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/pdf")
public class PdfController {

    private final PdfService pdfService;

    public PdfController(PdfService pdfService) {
        this.pdfService = pdfService;
    }

    // Vue에서 /api/convert-pdf 로 POST
    @PostMapping("/convert-pdf")
    public ResponseEntity<byte[]> convertPdf(@RequestBody Map<String, String> request) {
        try {
            String html = request.get("html"); // 클라이언트에서 전송한 HTML
            if (html == null) {
                return ResponseEntity.badRequest().build();
            }

            // 1. HTML → PDF 변환
            byte[] pdfBytes = pdfService.generatePdfFromHtml(html);

            // 2. HTTP 응답 헤더 설정
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_PDF);
            // 다운로드 되도록 Content-Disposition 설정
            headers.setContentDisposition(ContentDisposition.attachment().filename("LOTCard.pdf").build());

            // 3. PDF 바이트 반환
            return new ResponseEntity<>(pdfBytes, headers, HttpStatus.OK);

        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(("PDF 변환 실패: " + e.getMessage()).getBytes());
        }
    }
}

