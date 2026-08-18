/**
 * [API 호출] 요청 DTO.
 * key    : 인터페이스 식별자(IfEndpoint 이름, 예: DEPT_COST, WIP_SUBUL)
 * selCode: 결산코드(트랜잭션 적재 단위). 마스터는 무시.
 * params : 화면 조회조건. ERP=DataBlock1 필드, MES={factory,workDate,matId}.
 */
package com.dowinsys.cost.common.iface.vo;

import java.util.Map;

public class IfFetchRequest {
    private String key;
    private String yyyymm;     // 조회 년월 (운영 반영 대상 기간)
    private String selCode;    // 결산코드 (VN 실적='ACTUAL')
    private Map<String, Object> params;

    public String getKey() { return key; }
    public void setKey(String key) { this.key = key; }
    public String getYyyymm() { return yyyymm; }
    public void setYyyymm(String yyyymm) { this.yyyymm = yyyymm; }
    public String getSelCode() { return selCode; }
    public void setSelCode(String selCode) { this.selCode = selCode; }
    public Map<String, Object> getParams() { return params; }
    public void setParams(Map<String, Object> params) { this.params = params; }
}
