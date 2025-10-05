package com.dowinsys.cost.common.log.vo;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class SysLog {
	private String appNm;
    private String prod;
    private String userId;
    private String menuPath;
    private String menuUrl;
    private String tabPath;
    private String tabId;
    private String requestUri;
    private String menuId;
    private String queryId;
    private String ip;
    private String dateTimeStr;
}
