/**
 * 다국어 번역 Mapper
 */
package com.dowinsys.cost.common.i18n.mapper;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Map;

@Repository("com.dowinsys.cost.common.i18n.mapper.I18nMapper")
@Mapper
public interface I18nMapper {

    /**
     * DOI_I18N 테이블에서 번역 데이터 조회
     * @param lang 언어 코드 (vi)
     * @return KO_TEXT, VI_TEXT 포함된 맵 리스트
     */
    List<Map<String, Object>> selectI18nList(@Param("lang") String lang);
}
