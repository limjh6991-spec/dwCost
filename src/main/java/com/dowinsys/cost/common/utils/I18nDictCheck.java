package com.dowinsys.cost.common.utils;

import java.sql.*;

public class I18nDictCheck {
    public static void main(String[] args) throws Exception {
        String dbUrl = "jdbc:sqlserver://10.100.40.17:14233;databaseName=DWCMSTEST;encrypt=true;trustServerCertificate=true";
        Class.forName("com.microsoft.sqlserver.jdbc.SQLServerDriver");
        try (Connection conn = DriverManager.getConnection(dbUrl, "cost", "Dowoo1234!")) {
            Statement stmt = conn.createStatement();

            // 전체 통계
            ResultSet rs = stmt.executeQuery("SELECT COUNT(*) AS total, SUM(CASE WHEN VI_WORD != '' THEN 1 ELSE 0 END) AS translated FROM DOI_I18N_DICT WHERE USE_YN='Y'");
            rs.next();
            System.out.println("=== DOI_I18N_DICT 현황 ===");
            System.out.println("전체: " + rs.getInt("total") + "건");
            System.out.println("번역 완료: " + rs.getInt("translated") + "건\n");

            // 빈도 TOP 30 (번역 있는 것)
            rs = stmt.executeQuery("SELECT TOP 30 SEQ, KO_WORD, VI_WORD, FREQUENCY FROM DOI_I18N_DICT WHERE VI_WORD != '' ORDER BY FREQUENCY DESC");
            System.out.println("=== 번역 완료 (빈도 TOP 30) ===");
            System.out.printf("%-5s %-20s %-30s %s%n", "SEQ", "KO_WORD", "VI_WORD", "빈도");
            System.out.println("-".repeat(80));
            while (rs.next()) {
                System.out.printf("%-5d %-20s %-30s %d%n",
                    rs.getInt("SEQ"), rs.getNString("KO_WORD"), rs.getNString("VI_WORD"), rs.getInt("FREQUENCY"));
            }

            // 미번역 TOP 20
            rs = stmt.executeQuery("SELECT TOP 20 SEQ, KO_WORD, FREQUENCY FROM DOI_I18N_DICT WHERE VI_WORD = '' ORDER BY FREQUENCY DESC");
            System.out.println("\n=== 미번역 (빈도 TOP 20) ===");
            System.out.printf("%-5s %-20s %s%n", "SEQ", "KO_WORD", "빈도");
            System.out.println("-".repeat(50));
            while (rs.next()) {
                System.out.printf("%-5d %-20s %d%n",
                    rs.getInt("SEQ"), rs.getNString("KO_WORD"), rs.getInt("FREQUENCY"));
            }
        }
    }
}
