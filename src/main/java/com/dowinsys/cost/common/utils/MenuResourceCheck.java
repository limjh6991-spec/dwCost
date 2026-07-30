package com.dowinsys.cost.common.utils;

import java.sql.*;

public class MenuResourceCheck {
    public static void main(String[] args) throws Exception {
        String dbUrl = "jdbc:sqlserver://10.100.40.17:14233;databaseName=DWCMSTEST;encrypt=true;trustServerCertificate=true";
        Class.forName("com.microsoft.sqlserver.jdbc.SQLServerDriver");
        try (Connection conn = DriverManager.getConnection(dbUrl, "cost", "Dowoo1234!")) {
            Statement stmt = conn.createStatement();

            // 0. 테이블 구조 확인
            System.out.println("=== DOI_CM_SYS_RESOURCE 컬럼 구조 ===");
            ResultSet rs = stmt.executeQuery(
                "SELECT COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH " +
                "FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'DOI_CM_SYS_RESOURCE' ORDER BY ORDINAL_POSITION"
            );
            while (rs.next()) {
                System.out.printf("  %-25s %-15s %s%n",
                    rs.getString("COLUMN_NAME"), rs.getString("DATA_TYPE"),
                    rs.getString("CHARACTER_MAXIMUM_LENGTH") != null ? rs.getString("CHARACTER_MAXIMUM_LENGTH") : "");
            }

            // 1. DOI_CM_SYS_RESOURCE 전체 메뉴 트리
            System.out.println("\n=== DOI_CM_SYS_RESOURCE (개발DB 메뉴) ===");
            rs = stmt.executeQuery(
                "SELECT PROD_CATEGORY, SYS_RESOURCE_ID, UPPER_SYS_RESOURCE_ID, SYS_RESOURCE_NAME, DESCRIPTION " +
                "FROM DOI_CM_SYS_RESOURCE " +
                "ORDER BY PROD_CATEGORY, UPPER_SYS_RESOURCE_ID, SYS_RESOURCE_ID"
            );
            System.out.printf("%-5s %-15s %-15s %-30s %-30s%n",
                "PROD", "RESOURCE_ID", "UPPER_ID", "NAME", "DESCRIPTION");
            System.out.println("-".repeat(100));
            int menuCount = 0;
            while (rs.next()) {
                menuCount++;
                String prod = rs.getString("PROD_CATEGORY") != null ? rs.getString("PROD_CATEGORY") : "";
                System.out.printf("%-5s %-15s %-15s %-30s %-30s%n",
                    prod,
                    rs.getString("SYS_RESOURCE_ID"),
                    rs.getString("UPPER_SYS_RESOURCE_ID") != null ? rs.getString("UPPER_SYS_RESOURCE_ID") : "(ROOT)",
                    rs.getNString("SYS_RESOURCE_NAME"),
                    rs.getString("DESCRIPTION") != null ? rs.getString("DESCRIPTION") : "");
            }
            System.out.println("\n총 메뉴: " + menuCount + "건");

            // 2. 프론트엔드 라우터와 비교 (DESCRIPTION = URL 매핑)
            System.out.println("\n=== URL 매핑 있는 메뉴 (하위 메뉴) ===");
            rs = stmt.executeQuery(
                "SELECT SYS_RESOURCE_ID, SYS_RESOURCE_NAME, DESCRIPTION, PROD_CATEGORY " +
                "FROM DOI_CM_SYS_RESOURCE " +
                "WHERE DESCRIPTION IS NOT NULL AND DESCRIPTION != '' " +
                "ORDER BY PROD_CATEGORY, DESCRIPTION"
            );
            while (rs.next()) {
                System.out.printf("  [%s] %-15s %-25s -> %s%n",
                    rs.getString("PROD_CATEGORY"),
                    rs.getString("SYS_RESOURCE_ID"),
                    rs.getNString("SYS_RESOURCE_NAME"),
                    rs.getString("DESCRIPTION"));
            }

            // 3. PROD_CATEGORY별 개수
            System.out.println("\n=== PROD_CATEGORY별 메뉴 수 ===");
            rs = stmt.executeQuery(
                "SELECT PROD_CATEGORY, COUNT(*) as cnt " +
                "FROM DOI_CM_SYS_RESOURCE " +
                "GROUP BY PROD_CATEGORY"
            );
            while (rs.next()) {
                System.out.printf("  %s: %d건%n",
                    rs.getString("PROD_CATEGORY"),
                    rs.getInt("cnt"));
            }

            // 4. 역할-리소스 매핑 현황
            System.out.println("\n=== 역할-리소스 매핑 (DOI_CM_ROLE_SYS_RESOURCE) ===");
            rs = stmt.executeQuery(
                "SELECT a.ROLE_ID, b.ROLE_NAME, a.PROD_CATEGORY, COUNT(*) as menu_cnt " +
                "FROM DOI_CM_ROLE_SYS_RESOURCE a " +
                "LEFT JOIN DOI_CM_ROLE b ON a.ROLE_ID = b.ROLE_ID " +
                "GROUP BY a.ROLE_ID, b.ROLE_NAME, a.PROD_CATEGORY " +
                "ORDER BY a.ROLE_ID, a.PROD_CATEGORY"
            );
            while (rs.next()) {
                System.out.printf("  역할: %-10s (%-15s) [%s] 메뉴 %d건%n",
                    rs.getString("ROLE_ID"),
                    rs.getNString("ROLE_NAME") != null ? rs.getNString("ROLE_NAME") : "",
                    rs.getString("PROD_CATEGORY"),
                    rs.getInt("menu_cnt"));
            }

            // 5. VINA 유저의 역할 확인
            System.out.println("\n=== VINA 유저 역할 ===");
            rs = stmt.executeQuery(
                "SELECT a.USER_ID, a.ROLE_ID, b.ROLE_NAME " +
                "FROM DOI_CM_USER_ROLE a " +
                "LEFT JOIN DOI_CM_ROLE b ON a.ROLE_ID = b.ROLE_ID " +
                "WHERE a.USER_ID = 'VINA'"
            );
            boolean found = false;
            while (rs.next()) {
                found = true;
                System.out.printf("  %s -> %s (%s)%n",
                    rs.getString("USER_ID"),
                    rs.getString("ROLE_ID"),
                    rs.getNString("ROLE_NAME"));
            }
            if (!found) System.out.println("  (역할 매핑 없음!)");

            // 6. SYSADMIN 유저의 역할
            System.out.println("\n=== SYSADMIN 유저 역할 ===");
            rs = stmt.executeQuery(
                "SELECT a.USER_ID, a.ROLE_ID, b.ROLE_NAME " +
                "FROM DOI_CM_USER_ROLE a " +
                "LEFT JOIN DOI_CM_ROLE b ON a.ROLE_ID = b.ROLE_ID " +
                "WHERE a.USER_ID = 'SYSADMIN'"
            );
            while (rs.next()) {
                System.out.printf("  %s -> %s (%s)%n",
                    rs.getString("USER_ID"),
                    rs.getString("ROLE_ID"),
                    rs.getNString("ROLE_NAME"));
            }
        }
    }
}
