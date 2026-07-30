package com.dowinsys.cost.common.utils;

import java.sql.*;

public class UserCheck {
    public static void main(String[] args) throws Exception {
        String dbUrl = "jdbc:sqlserver://10.100.40.17:14233;databaseName=DWCMSTEST;encrypt=true;trustServerCertificate=true";
        Class.forName("com.microsoft.sqlserver.jdbc.SQLServerDriver");
        try (Connection conn = DriverManager.getConnection(dbUrl, "cost", "Dowoo1234!")) {
            Statement stmt = conn.createStatement();

            // dwvn 유저 확인
            ResultSet rs = stmt.executeQuery(
                "SELECT USER_ID, USER_NAME, PASSWORD, DEPT_NAME, DEPT_CODE, POSITION_NAME, DEL_YN, UTG, ITG " +
                "FROM DOI_CM_USER WHERE USER_ID LIKE '%dwvn%' OR USER_ID LIKE '%DWVN%' OR USER_ID LIKE '%vn%' OR USER_ID LIKE '%VN%' OR USER_ID LIKE '%vina%' OR USER_ID LIKE '%VINA%'"
            );

            System.out.println("=== dwvn 관련 유저 검색 ===");
            System.out.printf("%-15s %-15s %-20s %-10s %-10s %-8s %-5s %-5s%n",
                "USER_ID", "USER_NAME", "PASSWORD", "DEPT_NAME", "DEPT_CODE", "DEL_YN", "UTG", "ITG");
            System.out.println("-".repeat(100));
            boolean found = false;
            while (rs.next()) {
                found = true;
                System.out.printf("%-15s %-15s %-20s %-10s %-10s %-8s %-5s %-5s%n",
                    rs.getString("USER_ID"),
                    rs.getNString("USER_NAME"),
                    rs.getString("PASSWORD"),
                    rs.getNString("DEPT_NAME"),
                    rs.getString("DEPT_CODE"),
                    rs.getString("DEL_YN"),
                    rs.getString("UTG"),
                    rs.getString("ITG"));
            }
            if (!found) System.out.println("(검색 결과 없음)");

            // SYSADMIN, VINA 계정도 확인
            System.out.println("\n=== 주요 계정 확인 ===");
            rs = stmt.executeQuery(
                "SELECT USER_ID, USER_NAME, PASSWORD, DEL_YN, UTG " +
                "FROM DOI_CM_USER WHERE USER_ID IN ('SYSADMIN', 'VINA', 'dwvn', 'DWVN')"
            );
            while (rs.next()) {
                System.out.printf("%-15s %-15s %-20s DEL_YN=%-5s UTG=%-5s%n",
                    rs.getString("USER_ID"),
                    rs.getNString("USER_NAME"),
                    rs.getString("PASSWORD"),
                    rs.getString("DEL_YN"),
                    rs.getString("UTG"));
            }

            // 역할 매핑 확인
            System.out.println("\n=== dwvn 역할 매핑 ===");
            rs = stmt.executeQuery(
                "SELECT a.USER_ID, a.ROLE_ID, b.ROLE_NAME " +
                "FROM DOI_CM_USER_ROLE a LEFT JOIN DOI_CM_ROLE b ON a.ROLE_ID = b.ROLE_ID " +
                "WHERE a.USER_ID LIKE '%dwvn%' OR a.USER_ID LIKE '%DWVN%'"
            );
            found = false;
            while (rs.next()) {
                found = true;
                System.out.printf("  %s -> %s (%s)%n",
                    rs.getString("USER_ID"),
                    rs.getString("ROLE_ID"),
                    rs.getNString("ROLE_NAME"));
            }
            if (!found) System.out.println("  (역할 매핑 없음 - 로그인해도 메뉴가 안 보일 수 있음)");
        }
    }
}
