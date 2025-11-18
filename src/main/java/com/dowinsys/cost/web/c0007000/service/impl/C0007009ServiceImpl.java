/**
 * 타시스템 > 매출 정보
 */
package com.dowinsys.cost.web.c0007000.service.impl;

import com.dowinsys.cost.common.auth.service.AuthService;
import com.dowinsys.cost.component.JwtUtil;
import com.dowinsys.cost.web.c0007000.mapper.C0007009Mapper;
import com.dowinsys.cost.web.c0007000.service.C0007009Service;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;

@Service("com.dowinsys.cost.web.c0007000.service.C0007009")
public class C0007009ServiceImpl implements C0007009Service {

    @Autowired
    private C0007009Mapper mapper;

    @Autowired
    private JwtUtil jwtUtil;   // ✅ 방금 보여준 getUserId() 쓰기 위함

    @Override
    public List<Map<String, Object>> getRmaDataList(Map<String, Object> param) {
        return mapper.selectRmaData(param);
    }

    @Override
    public void insertRmaData(Map<String, Object> param) {
        // 로그인 사용자 ID
        String currentUserId = jwtUtil.getUserId();
        param.put("생성자", currentUserId);   // XML에서 #{생성자} 로 사용
        mapper.insertRmaData(param);
    }

    @Override
    public void updateRmaData(Map<String, Object> param) {
        String currentUserId = jwtUtil.getUserId();
        param.put("생성자", currentUserId);
        mapper.updateRmaData(param);
    }

    @Override
    public void deleteRmaData(Map<String, Object> param) {
        mapper.deleteRmaData(param);
    }

    @Override
    public List<Map<String, Object>> getModelPopup(Map<String, Object> param) {
        return mapper.selectModelPopup(param);
    }
}