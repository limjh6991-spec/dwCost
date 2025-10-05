package com.dowinsys.cost.common.generic.vo;

import java.util.List;
import java.util.Map;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Setter
@Getter
@NoArgsConstructor
public class QueryData {

	String queryId;
	List<Map<String, Object>> data;
}
