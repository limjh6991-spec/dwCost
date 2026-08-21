/**
 * [API 호출] 결과 DTO.
 */
package com.dowinsys.cost.common.iface.vo;

public class IfFetchResult {
    private String status;     // success | error
    private String key;
    private String requestId;
    private int loaded;        // 적재 건수
    private String message;
    private String debug;      // 진단용: 외부(ERP/MES) 실응답 원문(마스킹, 축약)

    public static IfFetchResult ok(String key, String requestId, int loaded) {
        IfFetchResult r = new IfFetchResult();
        r.status = "success";
        r.key = key;
        r.requestId = requestId;
        r.loaded = loaded;
        r.message = "적재 완료";
        return r;
    }

    public static IfFetchResult error(String key, String message) {
        IfFetchResult r = new IfFetchResult();
        r.status = "error";
        r.key = key;
        r.loaded = 0;
        r.message = message;
        return r;
    }

    public String getStatus() { return status; }
    public String getKey() { return key; }
    public String getRequestId() { return requestId; }
    public int getLoaded() { return loaded; }
    public String getMessage() { return message; }
    public String getDebug() { return debug; }
    public void setDebug(String debug) { this.debug = debug; }
}
