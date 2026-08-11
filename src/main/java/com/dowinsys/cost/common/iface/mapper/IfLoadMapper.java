/**
 * 인터페이스 적재 프로시저 호출 매퍼.
 * proc 이름은 서버측 레지스트리(IfEndpoint)에서만 오므로 ${proc} 동적 바인딩 안전.
 */
package com.dowinsys.cost.common.iface.mapper;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.springframework.stereotype.Repository;

@Repository("com.dowinsys.cost.common.iface.mapper.IfLoadMapper")
@Mapper
public interface IfLoadMapper {

    /** @selCode 사용 트랜잭션/조회 적재 (반환: 적재 건수) */
    int loadWithSel(@Param("proc") String proc,
                    @Param("json") String json,
                    @Param("selCode") String selCode,
                    @Param("requestId") String requestId);

    /** @selCode 미사용 마스터 적재 (반환: 적재 건수) */
    int loadMaster(@Param("proc") String proc,
                   @Param("json") String json,
                   @Param("requestId") String requestId);
}
