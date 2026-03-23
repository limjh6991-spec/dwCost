package com.dowinsys.cost.common.closingmonth.mapper;

import java.util.Map;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface CommonMapper {
    int isClosedMonth(Map<String, Object> param);
}
