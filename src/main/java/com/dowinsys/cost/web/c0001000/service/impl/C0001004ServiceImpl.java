package com.dowinsys.cost.web.c0001000.service.impl;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import com.dowinsys.cost.web.c0001000.mapper.C0001004Mapper;
import com.dowinsys.cost.web.c0001000.service.C0001004Service;

import java.util.Map;

@Service
public class C0001004ServiceImpl implements C0001004Service {
    @Autowired
    private C0001004Mapper mapper;

    // Tab1
    @Override
    public Object selectTab1GridData(Map<String, Object> params) {
        return mapper.selectTab1GridData(params);
    }
    @Override
    public Object insertTab1Data(Map<String, Object> body) {
        return mapper.insertTab1Data(body);
    }
    @Override
    public Object updateTab1Data(Map<String, Object> body) {
        return mapper.updateTab1Data(body);
    }
    @Override
    public Object deleteTab1Data(Map<String, Object> body) {
        return mapper.deleteTab1Data(body);
    }

    // Tab2
    @Override
    public Object selectTab2GridData(Map<String, Object> params) {
        return mapper.selectTab2GridData(params);
    }
    @Override
    public Object insertTab2Data(Map<String, Object> body) {
        return mapper.insertTab2Data(body);
    }
    @Override
    public Object updateTab2Data(Map<String, Object> body) {
        return mapper.updateTab2Data(body);
    }
    @Override
    public Object deleteTab2Data(Map<String, Object> body) {
        return mapper.deleteTab2Data(body);
    }

    // Tab3
    @Override
    public Object selectTab3GridData(Map<String, Object> params) {
        return mapper.selectTab3GridData(params);
    }
    @Override
    public Object insertTab3Data(Map<String, Object> body) {
        return mapper.insertTab3Data(body);
    }
    @Override
    public Object updateTab3Data(Map<String, Object> body) {
        return mapper.updateTab3Data(body);
    }
    @Override
    public Object deleteTab3Data(Map<String, Object> body) {
        return mapper.deleteTab3Data(body);
    }

    // Tab5
    @Override
    public Object selectTab5GridData(Map<String, Object> params) {
        return mapper.selectTab5GridData(params);
    }
    @Override
    public Object insertTab5Data(Map<String, Object> body) {
        return mapper.insertTab5Data(body);
    }
    @Override
    public Object updateTab5Data(Map<String, Object> body) {
        return mapper.updateTab5Data(body);
    }
    @Override
    public Object deleteTab5Data(Map<String, Object> body) {
        return mapper.deleteTab5Data(body);
    }
}    
