/**
 * 인터페이스 호출 실패 예외. 진단용 debug(마스킹된 요청 + 실응답)를 함께 실어
 * 컨트롤러가 화면(F12 res.debug)으로 전달할 수 있게 한다. (서버 로그 미가용 대비)
 */
package com.dowinsys.cost.common.iface;

public class IfFetchException extends RuntimeException {
    private final String debug;

    public IfFetchException(String message, String debug) {
        super(message);
        this.debug = debug;
    }

    public String getDebug() { return debug; }
}
