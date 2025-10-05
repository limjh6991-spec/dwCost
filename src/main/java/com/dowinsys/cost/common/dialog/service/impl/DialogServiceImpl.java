/**
*	Dialog 공통 팝업
*/
package com.dowinsys.cost.common.dialog.service.impl;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.dowinsys.cost.common.dialog.mapper.DialogMapper;
import com.dowinsys.cost.common.dialog.service.DialogService;

@Service("com.dowinsys.cost.common.dialog.service.DialogService")
public class DialogServiceImpl implements DialogService {

	@Autowired
	DialogMapper mapper;
}
