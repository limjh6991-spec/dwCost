package com.dowinsys.cost.common.generic.vo;

import java.util.List;
import java.util.Map;

import lombok.Getter;
import lombok.Setter;

@Setter
@Getter
public class GenericResourceVo {

	String menuId;
	String queryId;
	
	Map<String, Object> queryParams;
	
	List<QueryData> delete;
	List<QueryData> insert;
	List<QueryData> update;
}


