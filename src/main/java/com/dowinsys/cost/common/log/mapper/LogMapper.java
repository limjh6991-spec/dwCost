package com.dowinsys.cost.common.log.mapper;

import org.apache.ibatis.annotations.Mapper;

import com.dowinsys.cost.common.log.vo.SysLog;

@Mapper
public interface LogMapper {
	int insertSysLog(SysLog sysLog);
}
