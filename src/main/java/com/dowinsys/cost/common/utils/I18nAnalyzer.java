package com.dowinsys.cost.common.utils;

import java.sql.*;
import java.util.*;

/**
 * DOI_I18N 테이블 데이터 품질 분석
 * - 중복/동어반복 분석
 * - 카테고리별 분류
 * - 실제 사용 단어 수 추정
 */
public class I18nAnalyzer {

    public static void main(String[] args) {
        String dbUrl = "jdbc:sqlserver://10.100.40.17:14233;databaseName=DWCMSTEST;encrypt=true;trustServerCertificate=true";
        String user = "cost";
        String pass = "Dowoo1234!";

        try {
            Class.forName("com.microsoft.sqlserver.jdbc.SQLServerDriver");
            try (Connection conn = DriverManager.getConnection(dbUrl, user, pass)) {
                System.out.println("Connected!");
                Statement stmt = conn.createStatement();

                // 1. 전체 현황
                System.out.println("\n=== 1. 전체 현황 ===");
                ResultSet rs = stmt.executeQuery("SELECT COUNT(*) AS total FROM DOI_I18N");
                rs.next();
                System.out.println("  전체 레코드: " + rs.getInt("total"));

                // 2. KO_TEXT 기준 정확히 같은 텍스트 중복
                System.out.println("\n=== 2. KO_TEXT 완전 동일 중복 ===");
                rs = stmt.executeQuery(
                    "SELECT KO_TEXT, COUNT(*) AS cnt FROM DOI_I18N GROUP BY KO_TEXT HAVING COUNT(*) > 1 ORDER BY cnt DESC"
                );
                int dupCount = 0;
                int dupRows = 0;
                while (rs.next()) {
                    int cnt = rs.getInt("cnt");
                    dupCount++;
                    dupRows += (cnt - 1); // 1개만 남기면 이만큼 제거 가능
                    if (dupCount <= 20) {
                        System.out.println("  [" + cnt + "회] " + rs.getNString("KO_TEXT"));
                    }
                }
                System.out.println("  ... 총 " + dupCount + "개 중복 KO_TEXT, 제거 가능 행: " + dupRows);

                // 3. 고유한 KO_TEXT 수
                rs = stmt.executeQuery("SELECT COUNT(DISTINCT KO_TEXT) AS uniq FROM DOI_I18N");
                rs.next();
                System.out.println("  고유한 KO_TEXT: " + rs.getInt("uniq"));

                // 4. KO_TEXT 길이별 분포
                System.out.println("\n=== 3. KO_TEXT 길이별 분포 ===");
                rs = stmt.executeQuery(
                    "SELECT CASE WHEN LEN(KO_TEXT) <= 2 THEN '1-2자' " +
                    "WHEN LEN(KO_TEXT) <= 5 THEN '3-5자' " +
                    "WHEN LEN(KO_TEXT) <= 10 THEN '6-10자' " +
                    "WHEN LEN(KO_TEXT) <= 20 THEN '11-20자' " +
                    "WHEN LEN(KO_TEXT) <= 50 THEN '21-50자' " +
                    "ELSE '50자+' END AS len_group, COUNT(*) AS cnt " +
                    "FROM DOI_I18N GROUP BY CASE WHEN LEN(KO_TEXT) <= 2 THEN '1-2자' " +
                    "WHEN LEN(KO_TEXT) <= 5 THEN '3-5자' " +
                    "WHEN LEN(KO_TEXT) <= 10 THEN '6-10자' " +
                    "WHEN LEN(KO_TEXT) <= 20 THEN '11-20자' " +
                    "WHEN LEN(KO_TEXT) <= 50 THEN '21-50자' " +
                    "ELSE '50자+' END ORDER BY cnt DESC"
                );
                while (rs.next()) {
                    System.out.println("  " + rs.getString("len_group") + ": " + rs.getInt("cnt") + "건");
                }

                // 5. 유사 텍스트 그룹 (공백/특수문자 차이만 있는 것)
                System.out.println("\n=== 4. 유사 텍스트 분석 (공백 제거 후 동일) ===");
                rs = stmt.executeQuery(
                    "SELECT REPLACE(REPLACE(REPLACE(KO_TEXT, ' ', ''), N'　', ''), CHAR(9), '') AS normalized, " +
                    "COUNT(*) AS cnt FROM DOI_I18N " +
                    "GROUP BY REPLACE(REPLACE(REPLACE(KO_TEXT, ' ', ''), N'　', ''), CHAR(9), '') " +
                    "HAVING COUNT(*) > 1 ORDER BY cnt DESC"
                );
                int simCount = 0;
                int simRows = 0;
                while (rs.next()) {
                    int cnt = rs.getInt("cnt");
                    simCount++;
                    simRows += (cnt - 1);
                    if (simCount <= 15) {
                        System.out.println("  [" + cnt + "회] " + rs.getString("normalized"));
                    }
                }
                System.out.println("  ... 유사 중복 그룹: " + simCount + "개, 제거 가능: " + simRows + "행");

                // 6. VI_TEXT가 비어있거나 KO_TEXT와 동일한 것 (미번역)
                System.out.println("\n=== 5. 미번역/번역 불필요 ===");
                rs = stmt.executeQuery(
                    "SELECT COUNT(*) AS cnt FROM DOI_I18N WHERE VI_TEXT IS NULL OR VI_TEXT = '' OR VI_TEXT = KO_TEXT"
                );
                rs.next();
                System.out.println("  VI_TEXT가 NULL/빈값/KO와 동일: " + rs.getInt("cnt") + "건");

                // 7. 숫자/기호만으로 된 항목 (번역 불필요)
                System.out.println("\n=== 6. 번역 불필요 (숫자/기호만) ===");
                rs = stmt.executeQuery(
                    "SELECT COUNT(*) AS cnt FROM DOI_I18N " +
                    "WHERE KO_TEXT NOT LIKE N'%[가-힣]%' AND KO_TEXT NOT LIKE '%[a-zA-Z]%'"
                );
                rs.next();
                System.out.println("  한글/영문 없는 항목: " + rs.getInt("cnt") + "건");

                // 8. 실제 Vue 소스에서 사용되는 i18n 키 수 추정 (카테고리별)
                System.out.println("\n=== 7. CATEGORY별 분포 ===");
                rs = stmt.executeQuery(
                    "SELECT ISNULL(CATEGORY, 'NULL') AS cat, COUNT(*) AS cnt FROM DOI_I18N GROUP BY CATEGORY ORDER BY cnt DESC"
                );
                while (rs.next()) {
                    System.out.println("  " + rs.getString("cat") + ": " + rs.getInt("cnt") + "건");
                }

                // 9. 직역 품질 분석 - VI_TEXT가 너무 긴 경우 (직역 가능성)
                System.out.println("\n=== 8. 직역 의심 (VI_TEXT가 KO_TEXT의 3배 이상 긴 경우) ===");
                rs = stmt.executeQuery(
                    "SELECT TOP 20 KO_TEXT, VI_TEXT, LEN(KO_TEXT) AS ko_len, LEN(VI_TEXT) AS vi_len " +
                    "FROM DOI_I18N WHERE LEN(VI_TEXT) > LEN(KO_TEXT) * 3 AND LEN(KO_TEXT) >= 2 " +
                    "ORDER BY CAST(LEN(VI_TEXT) AS FLOAT) / LEN(KO_TEXT) DESC"
                );
                while (rs.next()) {
                    System.out.println("  KO[" + rs.getInt("ko_len") + "]: " + rs.getNString("KO_TEXT") +
                        " -> VI[" + rs.getInt("vi_len") + "]: " + rs.getNString("VI_TEXT"));
                }

                // 10. 최적화 시뮬레이션
                System.out.println("\n=== 9. 최적화 시뮬레이션 ===");
                rs = stmt.executeQuery("SELECT COUNT(*) FROM DOI_I18N");
                rs.next(); int total = rs.getInt(1);

                rs = stmt.executeQuery("SELECT COUNT(DISTINCT KO_TEXT) FROM DOI_I18N");
                rs.next(); int uniqueKo = rs.getInt(1);

                rs = stmt.executeQuery(
                    "SELECT COUNT(*) FROM DOI_I18N " +
                    "WHERE KO_TEXT NOT LIKE N'%[가-힣]%' AND KO_TEXT NOT LIKE '%[a-zA-Z]%'"
                );
                rs.next(); int noText = rs.getInt(1);

                System.out.println("  현재 총: " + total + "건");
                System.out.println("  중복 제거 후: " + uniqueKo + "건 (-" + (total - uniqueKo) + ")");
                System.out.println("  번역불필요 제거 후: ~" + (uniqueKo - noText) + "건 (-" + noText + ")");
                System.out.println("  예상 실제 필요 건수: ~" + (uniqueKo - noText) + "건");

                System.out.println("\nDONE!");
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
