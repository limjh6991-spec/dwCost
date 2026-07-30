package com.dowinsys.cost.common.utils;

import java.sql.*;

public class ExchangeRateInsert {
    public static void main(String[] args) throws Exception {
        String dbUrl = "jdbc:sqlserver://10.100.40.17:14233;databaseName=DWCMSTEST;encrypt=true;trustServerCertificate=true";
        Class.forName("com.microsoft.sqlserver.jdbc.SQLServerDriver");
        try (Connection conn = DriverManager.getConnection(dbUrl, "cost", "Dowoo1234!")) {
            conn.setAutoCommit(false);
            Statement stmt = conn.createStatement();
            try {
                // 1. 기존 데이터 확인
                System.out.println("=== DOI_EXCHANGE_RATE 기존 데이터 ===");
                ResultSet rs = stmt.executeQuery(
                    "SELECT TOP 20 * FROM DOI_EXCHANGE_RATE ORDER BY yyyymm DESC, 통화"
                );
                ResultSetMetaData meta = rs.getMetaData();
                int colCount = meta.getColumnCount();
                for (int i = 1; i <= colCount; i++) {
                    System.out.print(meta.getColumnName(i) + "\t");
                }
                System.out.println();
                while (rs.next()) {
                    for (int i = 1; i <= colCount; i++) {
                        System.out.print(rs.getString(i) + "\t");
                    }
                    System.out.println();
                }

                // 2. 2026년 5, 6월 평균 환율 입력
                // 2026년 5월 평균: USD=1, KRW=1370, VND=25850
                // 2026년 6월 평균: USD=1, KRW=1380, VND=25900
                System.out.println("\n=== 5, 6월 환율 입력 ===");

                String[][] rates = {
                    // {yyyymm, 통화, 환율}
                    {"202605", "KRW", "1370"},
                    {"202605", "VND", "25850"},
                    {"202606", "KRW", "1380"},
                    {"202606", "VND", "25900"},
                };

                for (String[] rate : rates) {
                    // 기존 데이터 확인
                    rs = stmt.executeQuery(
                        "SELECT COUNT(*) FROM DOI_EXCHANGE_RATE WHERE yyyymm='" + rate[0] + "' AND 통화=N'" + rate[1] + "'"
                    );
                    rs.next();
                    if (rs.getInt(1) > 0) {
                        stmt.executeUpdate(
                            "UPDATE DOI_EXCHANGE_RATE SET 환율=" + rate[2] + " WHERE yyyymm='" + rate[0] + "' AND 통화=N'" + rate[1] + "'"
                        );
                        System.out.println("  UPDATE: " + rate[0] + " " + rate[1] + " = " + rate[2]);
                    } else {
                        stmt.executeUpdate(
                            "INSERT INTO DOI_EXCHANGE_RATE (yyyymm, 통화, 환율) VALUES ('" + rate[0] + "', N'" + rate[1] + "', " + rate[2] + ")"
                        );
                        System.out.println("  INSERT: " + rate[0] + " " + rate[1] + " = " + rate[2]);
                    }
                }

                // 3. 결과 확인
                System.out.println("\n=== 입력 후 확인 ===");
                rs = stmt.executeQuery(
                    "SELECT * FROM DOI_EXCHANGE_RATE WHERE yyyymm IN ('202605','202606') ORDER BY yyyymm, 통화"
                );
                while (rs.next()) {
                    for (int i = 1; i <= colCount; i++) {
                        System.out.print(rs.getString(i) + "\t");
                    }
                    System.out.println();
                }

                conn.commit();
                System.out.println("\nCOMMIT 완료!");
            } catch (Exception e) {
                conn.rollback();
                System.out.println("ERROR - ROLLBACK!");
                e.printStackTrace();
            }
        }
    }
}
