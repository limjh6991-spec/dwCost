package com.dowinsys.cost.config;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;

/**
 * SPA(Vue) history 모드 fallback.
 *
 * Vue Router가 createWebHistory()(history 모드)를 사용하므로, /c0009000, /c0007002,
 * /main 같은 클라이언트 라우트를 브라우저에서 직접 새로고침하면 서버에 해당 경로의
 * 정적 리소스/컨트롤러가 없어 404(빈 화면)가 난다. 특히 사이트/언어 전환 시
 * window.location.reload()로 현재 라우트를 다시 로드할 때 이 문제가 발생한다.
 *
 * 아래 SPA 라우트들을 index.html로 forward 하여 Vue Router가 라우팅을 처리하도록 한다.
 * (/api/** 및 확장자 있는 정적 파일 /js /css /img 등은 대상이 아니며,
 *  더 구체적인 매핑/정적 리소스 핸들러가 우선하므로 영향 없음)
 */
@Controller
public class SpaForwardController {

    @GetMapping({
        "/main", "/login", "/WorkStatus",
        "/home/**", "/sample/**",
        "/c0*", "/c0*/**",
        "/m0*", "/m0*/**"
    })
    public String forward() {
        return "forward:/index.html";
    }
}
