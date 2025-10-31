
package com.dowinsys.cost.web.c0001000.service;

import java.util.Map;

import com.dowinsys.cost.common.auth.SysResource;

public interface C0001004Service {
    Object selectTab1GridData(Map<String, Object> params);
    Object insertTab1Data(Map<String, Object> body);
    Object updateTab1Data(Map<String, Object> body);
    Object deleteTab1Data(Map<String, Object> body);

    Object selectTab2GridData(Map<String, Object> params);
    Object insertTab2Data(Map<String, Object> body);
    Object updateTab2Data(Map<String, Object> body);
    Object deleteTab2Data(Map<String, Object> body);

    Object selectTab3GridData(Map<String, Object> params);
    Object insertTab3Data(Map<String, Object> body);
    Object updateTab3Data(Map<String, Object> body);
    Object deleteTab3Data(Map<String, Object> body);

    Object selectTab5GridData(Map<String, Object> params);
    Object insertTab5Data(Map<String, Object> body);
    Object updateTab5Data(Map<String, Object> body);
    Object deleteTab5Data(Map<String, Object> body);
}
