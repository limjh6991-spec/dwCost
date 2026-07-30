package com.dowinsys.cost.common.utils;

import java.sql.*;

public class MenuDetailCheck {
    public static void main(String[] args) throws Exception {
        String dbUrl = "jdbc:sqlserver://10.100.40.17:14233;databaseName=DWCMSTEST;encrypt=true;trustServerCertificate=true";
        Class.forName("com.microsoft.sqlserver.jdbc.SQLServerDriver");
        try (Connection conn = DriverManager.getConnection(dbUrl, "cost", "Dowoo1234!")) {
            Statement stmt = conn.createStatement();

            // 1. VN 제조원가 관련 메뉴 (C0003xxx)
            System.out.println("=== [VN] 제조_매출원가 메뉴 ===");
            ResultSet rs = stmt.executeQuery(
                "SELECT SYS_RESOURCE_ID, UPPER_SYS_RESOURCE_ID, SYS_RESOURCE_NAME, DESCRIPTION " +
                "FROM DOI_CM_SYS_RESOURCE " +
                "WHERE PROD_CATEGORY = 'VN' AND (SYS_RESOURCE_ID LIKE 'C0003%' OR SYS_RESOURCE_ID LIKE 'TAB030%') " +
                "ORDER BY UPPER_SYS_RESOURCE_ID, SYS_RESOURCE_ID"
            );
            while (rs.next()) {
                System.out.printf("  %-15s [상위:%-15s] %-25s -> %s%n",
                    rs.getString("SYS_RESOURCE_ID"),
                    rs.getString("UPPER_SYS_RESOURCE_ID") != null ? rs.getString("UPPER_SYS_RESOURCE_ID") : "",
                    rs.getNString("SYS_RESOURCE_NAME"),
                    rs.getString("DESCRIPTION") != null ? rs.getString("DESCRIPTION") : "");
            }

            // 2. HQ 제조원가 관련 메뉴 (C0003xxx)
            System.out.println("\n=== [HQ] 제조_매출원가 메뉴 ===");
            rs = stmt.executeQuery(
                "SELECT SYS_RESOURCE_ID, UPPER_SYS_RESOURCE_ID, SYS_RESOURCE_NAME, DESCRIPTION " +
                "FROM DOI_CM_SYS_RESOURCE " +
                "WHERE PROD_CATEGORY = 'HQ' AND (SYS_RESOURCE_ID LIKE 'C0003%' OR SYS_RESOURCE_ID LIKE 'TAB030%') " +
                "ORDER BY UPPER_SYS_RESOURCE_ID, SYS_RESOURCE_ID"
            );
            while (rs.next()) {
                System.out.printf("  %-15s [상위:%-15s] %-25s -> %s%n",
                    rs.getString("SYS_RESOURCE_ID"),
                    rs.getString("UPPER_SYS_RESOURCE_ID") != null ? rs.getString("UPPER_SYS_RESOURCE_ID") : "",
                    rs.getNString("SYS_RESOURCE_NAME"),
                    rs.getString("DESCRIPTION") != null ? rs.getString("DESCRIPTION") : "");
            }

            // 3. VN 타시스템 I/F 메뉴 (C0007xxx)
            System.out.println("\n=== [VN] 타시스템 I/F&Upload 메뉴 ===");
            rs = stmt.executeQuery(
                "SELECT SYS_RESOURCE_ID, UPPER_SYS_RESOURCE_ID, SYS_RESOURCE_NAME, DESCRIPTION " +
                "FROM DOI_CM_SYS_RESOURCE " +
                "WHERE PROD_CATEGORY = 'VN' AND (SYS_RESOURCE_ID LIKE 'C0007%' OR SYS_RESOURCE_ID LIKE 'TAB070%') " +
                "ORDER BY UPPER_SYS_RESOURCE_ID, SYS_RESOURCE_ID"
            );
            while (rs.next()) {
                System.out.printf("  %-15s [상위:%-15s] %-25s -> %s%n",
                    rs.getString("SYS_RESOURCE_ID"),
                    rs.getString("UPPER_SYS_RESOURCE_ID") != null ? rs.getString("UPPER_SYS_RESOURCE_ID") : "",
                    rs.getNString("SYS_RESOURCE_NAME"),
                    rs.getString("DESCRIPTION") != null ? rs.getString("DESCRIPTION") : "");
            }

            // 4. HQ 타시스템 I/F 메뉴
            System.out.println("\n=== [HQ] 타시스템 I/F&Upload 메뉴 ===");
            rs = stmt.executeQuery(
                "SELECT SYS_RESOURCE_ID, UPPER_SYS_RESOURCE_ID, SYS_RESOURCE_NAME, DESCRIPTION " +
                "FROM DOI_CM_SYS_RESOURCE " +
                "WHERE PROD_CATEGORY = 'HQ' AND (SYS_RESOURCE_ID LIKE 'C0007%' OR SYS_RESOURCE_ID LIKE 'TAB070%') " +
                "ORDER BY UPPER_SYS_RESOURCE_ID, SYS_RESOURCE_ID"
            );
            while (rs.next()) {
                System.out.printf("  %-15s [상위:%-15s] %-25s -> %s%n",
                    rs.getString("SYS_RESOURCE_ID"),
                    rs.getString("UPPER_SYS_RESOURCE_ID") != null ? rs.getString("UPPER_SYS_RESOURCE_ID") : "",
                    rs.getNString("SYS_RESOURCE_NAME"),
                    rs.getString("DESCRIPTION") != null ? rs.getString("DESCRIPTION") : "");
            }

            // 5. 본사(HQ) 재료비집계/배부 탭 확인
            System.out.println("\n=== 본사 TAB030003/004 (재료비) 현황 ===");
            rs = stmt.executeQuery(
                "SELECT PROD_CATEGORY, SYS_RESOURCE_ID, UPPER_SYS_RESOURCE_ID, SYS_RESOURCE_NAME " +
                "FROM DOI_CM_SYS_RESOURCE " +
                "WHERE SYS_RESOURCE_ID IN ('TAB030003','TAB030004','TAB030009','TAB030010','TAB030011','TAB030012') " +
                "ORDER BY PROD_CATEGORY, SYS_RESOURCE_ID"
            );
            while (rs.next()) {
                System.out.printf("  [%s] %-15s [상위:%-15s] %s%n",
                    rs.getString("PROD_CATEGORY"),
                    rs.getString("SYS_RESOURCE_ID"),
                    rs.getString("UPPER_SYS_RESOURCE_ID"),
                    rs.getNString("SYS_RESOURCE_NAME"));
            }

            // 6. VINA 역할에 매핑된 제조원가 메뉴
            System.out.println("\n=== BIZADMIN 역할 -> VN 제조원가 메뉴 매핑 ===");
            rs = stmt.executeQuery(
                "SELECT a.SYS_RESOURCE_ID, b.SYS_RESOURCE_NAME, b.DESCRIPTION " +
                "FROM DOI_CM_ROLE_SYS_RESOURCE a " +
                "JOIN DOI_CM_SYS_RESOURCE b ON a.SYS_RESOURCE_ID = b.SYS_RESOURCE_ID AND a.PROD_CATEGORY = b.PROD_CATEGORY " +
                "WHERE a.ROLE_ID = 'BIZADMIN' AND a.PROD_CATEGORY = 'VN' " +
                "AND (a.SYS_RESOURCE_ID LIKE 'C0003%' OR a.SYS_RESOURCE_ID LIKE 'TAB030%' OR a.SYS_RESOURCE_ID LIKE 'C0007%' OR a.SYS_RESOURCE_ID LIKE 'TAB070%') " +
                "ORDER BY a.SYS_RESOURCE_ID"
            );
            while (rs.next()) {
                System.out.printf("  %-15s %-25s %s%n",
                    rs.getString("SYS_RESOURCE_ID"),
                    rs.getNString("SYS_RESOURCE_NAME"),
                    rs.getString("DESCRIPTION") != null ? rs.getString("DESCRIPTION") : "");
            }
        }
    }
}
