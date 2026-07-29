/**
 * 다국어 번역 API - DOI_I18N / DOI_I18N_DICT 테이블에서 번역 데이터 조회
 * GET /api/public/i18n?lang=vi       → 1차 테이블 (전체 텍스트 매칭)
 * GET /api/public/i18n/dict?lang=vi  → 2차 사전 (단어 단위 매칭) ★ 권장
 */
package com.dowinsys.cost.common.i18n.controller;

import com.dowinsys.cost.common.i18n.mapper.I18nMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@RestController("com.dowinsys.cost.common.i18n.controller.I18nController")
@RequestMapping("/api/public/i18n")
public class I18nController {

    @Autowired
    I18nMapper i18nMapper;

    /**
     * 1차 테이블: 전체 텍스트 매칭 (하위 호환)
     */
    @GetMapping("")
    public ResponseEntity<Map<String, Object>> getTranslations(
            @RequestParam(value = "lang", defaultValue = "vi") String lang) {
        
        List<Map<String, Object>> rows = i18nMapper.selectI18nList(lang);
        
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

    /**
     * 2차 사전: 단어 단위 매칭 (긴 단어 우선 정렬)
     * 프론트엔드에서 텍스트 내 한국어 부분을 단어 단위로 치환
     */
    @GetMapping("/dict")
    public ResponseEntity<Map<String, Object>> getDictionary(
            @RequestParam(value = "lang", defaultValue = "vi") String lang) {
        
        List<Map<String, Object>> rows = i18nMapper.selectI18nDict(lang);
        
        // LinkedHashMap으로 순서 유지 (긴 단어 먼저)
        Map<String, String> dict = new LinkedHashMap<>();
        for (Map<String, Object> row : rows) {
            String koWord = row.get("KO_WORD") != null ? row.get("KO_WORD").toString() : null;
            String viWord = row.get("VI_WORD") != null ? row.get("VI_WORD").toString() : null;
            if (koWord != null && viWord != null && !viWord.isEmpty()) {
                dict.put(koWord, viWord);
            }
        }
        
        Map<String, Object> result = new HashMap<>();
        result.put("lang", lang);
        result.put("count", dict.size());
        result.put("dict", dict);
        
        return ResponseEntity.ok(result);
    }
}
