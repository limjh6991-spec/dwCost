package com.dowinsys.cost.common.log;

import com.p6spy.engine.logging.Category;
import com.p6spy.engine.spy.appender.P6Logger;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class SqlFilterLogger implements P6Logger {

    private static final Logger logger = LoggerFactory.getLogger("p6spy");

    @Override
    public void logSQL(int connectionId, String now, long elapsed, Category category,
                       String prepared, String sql, String url) {

        if (sql != null && sql.contains("SKIP_LOG")) {
            return;
        }

        // 로그 메시지 생성
        String logMessage = String.format("[%s] Execution Time: %dms\n\t%s", now, elapsed, sql);

        // SLF4J로 로그 출력 (logback의 설정에 따라 파일로 기록됨)
        logger.info(logMessage);
    }

    @Override
    public void logException(Exception e) {
        logger.error("P6Spy SQL Exception", e);
    }

    @Override
    public void logText(String text) {
        logger.debug(text);
    }

    @Override
    public boolean isCategoryEnabled(Category category) {
        return true;
    }
}
