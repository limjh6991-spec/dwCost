/**
 * 타시스템 > 환율관리 (월평균, VINA USD 환산 — 수동 입력)
 * - 조회/저장은 제네릭 search/saveData(menuId=c0007012)로 처리되므로
 *   본 인터페이스는 매퍼 네임스페이스 바인딩(@MapperScan)용으로만 존재한다.
 */
package com.dowinsys.cost.web.c0007000.mapper;

import org.apache.ibatis.annotations.Mapper;
import org.springframework.stereotype.Repository;

@Repository("com.dowinsys.cost.web.c0007000.mapper.C0007012Mapper")
@Mapper
public interface C0007012Mapper {
}
