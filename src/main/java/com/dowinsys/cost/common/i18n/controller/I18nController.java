/**
 * 다국어 번역 API - DOI_I18N 테이블에서 번역 데이터 조회
 * GET /api/public/i18n?lang=vi  (인증 불필요)
 */
package com.dowinsys.cost.common.i18n.controller;

import com.dowinsys.cost.common.i18n.mapper.I18nMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController("com.dowinsys.cost.common.i18n.controller.I18nController")
@RequestMapping("/api/public/i18n")
public class I18nController {

    @Autowired
    I18nMapper i18nMapper;

    /**
     * 번역 데이터를 KO_TEXT:VI_TEXT 맵으로 반환
     * @param lang 언어 코드 (vi)
     * @return { "ko_text": "vi_text", ... }
     */
    @GetMapping("")
    public ResponseEntity<Map<String, Object>> getTranslations(
            @RequestParam(value = "lang", defaultValue = "vi") String lang) {
        
        List<Map<String, Object>> rows = i18nMapper.selectI18nList(lang);
        
        // KO_TEXT → VI_TEXT 맵 구성
        Map<String, String> translations = new HashMap<>();
        for (Map<String, Object> row : rows) {
            String koText = row.get("KO_TEXT") != null ? row.get("KO_TEXT").toString() : null;
            String viText = row.get("VI_TEXT") != null ? row.get("VI_TEXT").toString() : null;
            if (koText != null && viText != null && !viText.isEmpty()) {
                translations.put(koText, viText);
            }
        }
        
        Map<String, Object> result = new HashMap<>();
        result.put("lang", lang);
        result.put("count", translations.size());
        result.put("translations", translations);
        
        return ResponseEntity.ok(result);
    }
}
