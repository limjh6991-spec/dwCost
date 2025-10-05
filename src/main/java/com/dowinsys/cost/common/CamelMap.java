package com.dowinsys.cost.common;

import java.util.HashMap;

import org.apache.commons.text.CaseUtils;

public class CamelMap<K, V> extends HashMap<K, V> {

	private static final long serialVersionUID = 3335834668146054241L;

	@Override
    public V put(K key, V value) {
        // 키를 스네이크 케이스에서 카멜 케이스로 변환
        K camelKey = (K) CaseUtils.toCamelCase(key.toString(), false, '_');
        return super.put(camelKey, value);
    }
}