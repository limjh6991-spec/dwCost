package com.dowinsys.cost.common.enums;

public enum MatTypeEnum {
	
    GLASS("10", "GLASS", "원자재"),
    DUMMY("20", "DUMMY", "더미 글라스"),
    FILM("20", "FILM", "필름"),
    TRAY("20", "TRAY", "트레이"),
    CHEMICAL("30", "CHEMICAL", "약액"),
    RESIN("30", "RESIN", "레진"),
    FILTER("40", "FILTER", "필터"),
    TOOL("40", "TOOL", "툴"),
    ETC("60", "ETC", "포장재/기타")
    ;

    private final String matCategoryCode;
    private final String matTypeCode;
    private final String matName;

    MatTypeEnum(String matCategoryCode, String matTypeCode, String matName) {
        this.matCategoryCode = matCategoryCode;
        this.matTypeCode = matTypeCode;
        this.matName = matName;
    }

    public String getMatCategoryCode() {
        return matCategoryCode;
    }

    public String getMatTypeCode() {
        return matTypeCode;
    }
    
    public String getMatName() {
        return matName;
    }    
}
