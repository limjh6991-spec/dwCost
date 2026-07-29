package com.dowinsys.cost.common.utils;

import java.io.*;
import java.nio.charset.StandardCharsets;
import java.sql.*;
import java.util.*;

/**
 * ko_to_vi_v2.json → DOI_I18N 테이블 동기화
 * 기존 데이터를 삭제하고 v2 JSON 기반으로 재생성
 */
public class I18nSync {

    public static void main(String[] args) throws Exception {
        String dbUrl = "jdbc:sqlserver://10.100.40.17:14233;databaseName=DWCMSTEST;encrypt=true;trustServerCertificate=true";
        String user = "cost";
        String pass = "Dowoo1234!";

        // v2 JSON 파일 읽기
        String jsonPath = "src/main/vue/src/assets/i18n/ko_to_vi_v2.json";
        File jsonFile = new File(jsonPath);
        if (!jsonFile.exists()) {
            System.out.println("JSON file not found: " + jsonFile.getAbsolutePath());
            return;
        }

        StringBuilder sb = new StringBuilder();
        try (BufferedReader reader = new BufferedReader(new InputStreamReader(new FileInputStream(jsonFile), StandardCharsets.UTF_8))) {
            String line;
            while ((line = reader.readLine()) != null) sb.append(line).append("\n");
        }
        String jsonStr = sb.toString();

        // 간단한 JSON 파싱 (key-value)
        Map<String, String> translations = new LinkedHashMap<>();
        String[] lines = jsonStr.split("\n");
        for (String line : lines) {
            line = line.trim();
            if (line.startsWith("\"") && line.contains("\": \"")) {
                int keyEnd = line.indexOf("\": \"");
                String key = line.substring(1, keyEnd);
                String valStart = line.substring(keyEnd + 4);
                String val = valStart;
                if (val.endsWith("\",") || val.endsWith("\"")) {
                    val = val.substring(0, val.lastIndexOf("\""));
                }
                // unescape
                key = key.replace("\\\"", "\"").replace("\\\\", "\\").replace("\\n", "\n");
                val = val.replace("\\\"", "\"").replace("\\\\", "\\").replace("\\n", "\n");
                translations.put(key, val);
            }
        }

        System.out.println("v2 JSON 로드: " + translations.size() + "건");
        int withTranslation = 0;
        for (String v : translations.values()) {
            if (v != null && !v.isEmpty()) withTranslation++;
        }
        System.out.println("  번역 있음: " + withTranslation + "건");
        System.out.println("  미번역: " + (translations.size() - withTranslation) + "건");

        Class.forName("com.microsoft.sqlserver.jdbc.SQLServerDriver");
        try (Connection conn = DriverManager.getConnection(dbUrl, user, pass)) {
            System.out.println("\nConnected to DWCMSTEST!");
            conn.setAutoCommit(false);

            try {
                // 1. 기존 데이터 삭제
                Statement stmt = conn.createStatement();
                ResultSet rs = stmt.executeQuery("SELECT COUNT(*) FROM DOI_I18N");
                rs.next();
                int oldCount = rs.getInt(1);
                System.out.println("\n기존 데이터: " + oldCount + "건");

                stmt.executeUpdate("DELETE FROM DOI_I18N");
                System.out.println("기존 데이터 삭제 완료");

                // 2. v2 데이터 INSERT
                PreparedStatement ps = conn.prepareStatement(
                    "INSERT INTO DOI_I18N (SEQ, KO_TEXT, VI_TEXT, CATEGORY, USE_YN, REG_DATE) " +
                    "VALUES (?, ?, ?, 'COMMON', 'Y', GETDATE())"
                );

                int seq = 1;
                int inserted = 0;
                for (Map.Entry<String, String> entry : translations.entrySet()) {
                    String ko = entry.getKey();
                    String vi = entry.getValue();
                    
                    ps.setInt(1, seq++);
                    ps.setNString(2, ko);
                    ps.setNString(3, vi != null && !vi.isEmpty() ? vi : "");
                    ps.addBatch();
                    inserted++;

                    if (inserted % 500 == 0) {
                        ps.executeBatch();
                        System.out.println("  INSERT 진행: " + inserted + "건...");
                    }
                }
                ps.executeBatch();
                System.out.println("INSERT 완료: " + inserted + "건");

                // 3. 검증
                rs = stmt.executeQuery("SELECT COUNT(*) FROM DOI_I18N");
                rs.next();
                System.out.println("\n검증 - 전체: " + rs.getInt(1) + "건");

                rs = stmt.executeQuery("SELECT COUNT(*) FROM DOI_I18N WHERE VI_TEXT IS NOT NULL AND VI_TEXT != ''");
                rs.next();
                System.out.println("검증 - 번역됨: " + rs.getInt(1) + "건");

                rs = stmt.executeQuery("SELECT COUNT(*) FROM DOI_I18N WHERE USE_YN = 'Y'");
                rs.next();
                System.out.println("검증 - 사용중: " + rs.getInt(1) + "건");

                conn.commit();
                System.out.println("\n커밋 완료!");
                System.out.println(oldCount + "건 → " + inserted + "건 (" + 
                    (oldCount > inserted ? "-" + (oldCount - inserted) : "+" + (inserted - oldCount)) + ")");

            } catch (Exception e) {
                conn.rollback();
                System.out.println("ERROR - 롤백!");
                e.printStackTrace();
            }
        }
    }
}
