package com.dowinsys.cost.common.utils;

import java.sql.*;

/**
 * VN에서 본사 전용 재료비 탭(TAB030001~005) 제거
 * - DOI_CM_SYS_RESOURCE에서 VN 본사 탭 삭제
 * - DOI_CM_ROLE_SYS_RESOURCE에서 VN 본사 탭 역할 매핑 삭제
 */
public class FixVnCostMenu {
    public static void main(String[] args) throws Exception {
        String dbUrl = "jdbc:sqlserver://10.100.40.17:14233;databaseName=DWCMSTEST;encrypt=true;trustServerCertificate=true";
        Class.forName("com.microsoft.sqlserver.jdbc.SQLServerDriver");
        try (Connection conn = DriverManager.getConnection(dbUrl, "cost", "Dowoo1234!")) {
            conn.setAutoCommit(false);
            Statement stmt = conn.createStatement();

            try {
                // 1. 변경 전 VN 제조원가 탭 현황
                System.out.println("=== 변경 전: VN 제조원가 탭 ===");
                ResultSet rs = stmt.executeQuery(
                    "SELECT SYS_RESOURCE_ID, SYS_RESOURCE_NAME " +
                    "FROM DOI_CM_SYS_RESOURCE " +
                    "WHERE PROD_CATEGORY = 'VN' AND SYS_RESOURCE_ID LIKE 'TAB030%' AND UPPER_SYS_RESOURCE_ID = 'C0003001' " +
                    "ORDER BY SYS_RESOURCE_ID"
                );
                while (rs.next()) {
                    System.out.println("  " + rs.getString("SYS_RESOURCE_ID") + " - " + rs.getNString("SYS_RESOURCE_NAME"));
                }

                // 2. VN 역할 매핑에서 본사 탭 제거
                System.out.println("\n=== 역할 매핑 제거 ===");
                int deleted1 = stmt.executeUpdate(
                    "DELETE FROM DOI_CM_ROLE_SYS_RESOURCE " +
                    "WHERE PROD_CATEGORY = 'VN' " +
                    "AND SYS_RESOURCE_ID IN ('TAB030001','TAB030002','TAB030003','TAB030004','TAB030005')"
                );
                System.out.println("  DOI_CM_ROLE_SYS_RESOURCE 삭제: " + deleted1 + "건");

                // 3. VN 메뉴에서 본사 탭 제거
                System.out.println("\n=== 메뉴 제거 ===");
                int deleted2 = stmt.executeUpdate(
                    "DELETE FROM DOI_CM_SYS_RESOURCE " +
                    "WHERE PROD_CATEGORY = 'VN' " +
                    "AND SYS_RESOURCE_ID IN ('TAB030001','TAB030002','TAB030003','TAB030004','TAB030005')"
                );
                System.out.println("  DOI_CM_SYS_RESOURCE 삭제: " + deleted2 + "건");

                // 4. 변경 후 VN 제조원가 탭 현황
                System.out.println("\n=== 변경 후: VN 제조원가 탭 ===");
                rs = stmt.executeQuery(
                    "SELECT SYS_RESOURCE_ID, SYS_RESOURCE_NAME, DESCRIPTION " +
                    "FROM DOI_CM_SYS_RESOURCE " +
                    "WHERE PROD_CATEGORY = 'VN' AND SYS_RESOURCE_ID LIKE 'TAB030%' AND UPPER_SYS_RESOURCE_ID = 'C0003001' " +
                    "ORDER BY SYS_RESOURCE_ID"
                );
                while (rs.next()) {
                    System.out.println("  " + rs.getString("SYS_RESOURCE_ID") + " - " + 
                        rs.getNString("SYS_RESOURCE_NAME") + " -> " + 
                        (rs.getString("DESCRIPTION") != null ? rs.getString("DESCRIPTION") : ""));
                }

                // 5. HQ 제조원가 탭 변경 없음 확인
                System.out.println("\n=== HQ 제조원가 탭 (변경 없음 확인) ===");
                rs = stmt.executeQuery(
                    "SELECT SYS_RESOURCE_ID, SYS_RESOURCE_NAME " +
                    "FROM DOI_CM_SYS_RESOURCE " +
                    "WHERE PROD_CATEGORY = 'HQ' AND SYS_RESOURCE_ID LIKE 'TAB030%' AND UPPER_SYS_RESOURCE_ID = 'C0003001' " +
                    "ORDER BY SYS_RESOURCE_ID"
                );
                while (rs.next()) {
                    System.out.println("  " + rs.getString("SYS_RESOURCE_ID") + " - " + rs.getNString("SYS_RESOURCE_NAME"));
                }

                conn.commit();
                System.out.println("\n커밋 완료!");

            } catch (Exception e) {
                conn.rollback();
                System.out.println("ERROR - 롤백!");
                e.printStackTrace();
            }
        }
    }
}
