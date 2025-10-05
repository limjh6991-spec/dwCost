package com.dowinsys.cost.common.generic.service;

import java.util.List;
import java.util.Map;

import com.dowinsys.cost.common.generic.vo.GenericResourceVo;

public interface GenericResourceService {

	List<Map<String, Object>> search(GenericResourceVo grv);

	void saveData(GenericResourceVo grv);
}
