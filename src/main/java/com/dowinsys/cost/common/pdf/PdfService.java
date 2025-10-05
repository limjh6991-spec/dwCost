package com.dowinsys.cost.common.pdf;

import java.io.ByteArrayOutputStream;
import java.io.File;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import com.openhtmltopdf.pdfboxout.PdfRendererBuilder;

import org.jsoup.Jsoup;
import org.jsoup.nodes.Document;
import org.jsoup.nodes.Entities;
import org.jsoup.nodes.Element;

@Service
public class PdfService {
	
	@Value("${pdf.base-uri}")
    private String baseUri;
	
	public String fixXhtmlIssues(String html) {
		try {
            // 1. Jsoup로 HTML 파싱 (HTML 모드)
            Document doc = Jsoup.parse(html);
            
            doc.outputSettings()
            .syntax(Document.OutputSettings.Syntax.xml)          // XML 모드
            .escapeMode(Entities.EscapeMode.xhtml)               // XHTML 엔티티
            .prettyPrint(false);    
            
            // Jsoup가 <br>를 자동으로 빈 요소로 처리해 <br /> 형태로 직렬화해줄 수도 있습니다.
            
            // - data-v-* 속성 제거
            //   예: [^"]* 부분이 들어가면 value까지 포함. 상황에 따라 다르게.
            doc.select("*[data-v-]").removeAttr("data-v-");
            
            //style 추가
            doc.select("head").append("<link rel=\"stylesheet\" href=\"/css/pdf.css\" />");
            
            // 3. XHTML 문법 준수를 위해, doc를 XHTML로 변환
            //    Jsoup 자체적으로 XML Declaration을 붙이거나, <br />로 변환할 수 있음.
            //    보통 doc.html()은 HTML5 형식으로 직렬화, doc.outerHtml()도 유사
            return doc.outerHtml();
        } catch (Exception e) {
            e.printStackTrace();
            return html; // 실패 시 원본 반환
        }
	}
    public byte[] generatePdfFromHtml(String htmlContent) {
    	String parsedHtml = fixXhtmlIssues(htmlContent);
        try (ByteArrayOutputStream os = new ByteArrayOutputStream()) {
            PdfRendererBuilder builder = new PdfRendererBuilder();
            
            // HTML 문자열과 baseUri(이미지/CSS 경로 설정) 지정
            builder.withHtmlContent(parsedHtml, baseUri);
            //builder.useFont(new File("resources/static/css/NotoSansKR-Regular.ttf"), "NotoSansKR");
            builder.toStream(os);
            builder.run();
            return os.toByteArray();
        } catch (Exception e) {
            throw new RuntimeException("PDF 생성 중 오류 발생", e);
        }
    }
}
