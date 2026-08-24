/**
 * 인터페이스 연결/인증 설정 (application.yml `iface:` 바인딩).
 * 인증정보(certId/certKey/dsnOper/dsnBis)는 코드/설정파일에 하드코딩하지 않고
 * 환경변수(예: ${IFACE_ERP_CERT_ID})로 주입한다. 실제 값은 운영 서버 env 에서 관리.
 */
package com.dowinsys.cost.common.iface.config;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

@Component
@ConfigurationProperties(prefix = "iface")
public class IfProperties {

    private Erp erp = new Erp();
    private Mes mes = new Mes();
    private int connectTimeoutMs = 10000;
    private int readTimeoutMs = 120000;

    public static class Erp {
        /** 예) http://172.16.21.32:8801 (TEST) — VN(비나) 영림원 서버 */
        private String baseUrl;
        /** HQ(본사) 영림원 서버 base-url. 미설정 시 baseUrl 로 폴백. (HQ는 회사구분=서버주소 상이) */
        private String hqBaseUrl;
        private String certId;
        private String certKey;
        private String dsnOper;
        private String dsnBis;
        private int companySeq = 1;
        private int languageSeq = 6;
        private int userSeq = 3;

        public String getBaseUrl() { return baseUrl; }
        public void setBaseUrl(String baseUrl) { this.baseUrl = baseUrl; }
        public String getHqBaseUrl() { return hqBaseUrl; }
        public void setHqBaseUrl(String hqBaseUrl) { this.hqBaseUrl = hqBaseUrl; }
        /** site 별 ERP base-url (HQ→hqBaseUrl, 없으면 baseUrl 폴백) */
        public String baseUrlFor(String site) {
            if ("HQ".equalsIgnoreCase(site) && hqBaseUrl != null && !hqBaseUrl.isBlank()) return hqBaseUrl;
            return baseUrl;
        }
        public String getCertId() { return certId; }
        public void setCertId(String certId) { this.certId = certId; }
        public String getCertKey() { return certKey; }
        public void setCertKey(String certKey) { this.certKey = certKey; }
        public String getDsnOper() { return dsnOper; }
        public void setDsnOper(String dsnOper) { this.dsnOper = dsnOper; }
        public String getDsnBis() { return dsnBis; }
        public void setDsnBis(String dsnBis) { this.dsnBis = dsnBis; }
        public int getCompanySeq() { return companySeq; }
        public void setCompanySeq(int companySeq) { this.companySeq = companySeq; }
        public int getLanguageSeq() { return languageSeq; }
        public void setLanguageSeq(int languageSeq) { this.languageSeq = languageSeq; }
        public int getUserSeq() { return userSeq; }
        public void setUserSeq(int userSeq) { this.userSeq = userSeq; }
    }

    public static class Mes {
        /** 예) http://172.16.23.30:8888 */
        private String baseUrl;
        public String getBaseUrl() { return baseUrl; }
        public void setBaseUrl(String baseUrl) { this.baseUrl = baseUrl; }
    }

    public Erp getErp() { return erp; }
    public void setErp(Erp erp) { this.erp = erp; }
    public Mes getMes() { return mes; }
    public void setMes(Mes mes) { this.mes = mes; }
    public int getConnectTimeoutMs() { return connectTimeoutMs; }
    public void setConnectTimeoutMs(int connectTimeoutMs) { this.connectTimeoutMs = connectTimeoutMs; }
    public int getReadTimeoutMs() { return readTimeoutMs; }
    public void setReadTimeoutMs(int readTimeoutMs) { this.readTimeoutMs = readTimeoutMs; }

    public boolean isErpCertConfigured() {
        return notBlank(erp.certId) && notBlank(erp.certKey)
                && notBlank(erp.dsnOper) && notBlank(erp.dsnBis);
    }

    private static boolean notBlank(String s) { return s != null && !s.isBlank(); }
}
