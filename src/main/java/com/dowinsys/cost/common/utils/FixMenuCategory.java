package com.dowinsys.cost.common.utils;

import java.sql.*;

/**
 * DOI_CM_SYS_RESOURCE / doi_cm_role_sys_resource 의 PROD_CATEGORY 보정
 * COST -> HQ 로 변경 (selectAuthMenuTabList가 HQ/VN으로 조회하므로)
 */
public class FixMenuCategory {

    public static void main(String[] args) {
        String dbUrl = "jdbc:sqlserver://10.100.40.17:14233;databaseName=DWCMSTEST;encrypt=true;trustServerCertificate=true";
        String user = "cost";
        String pass = "Dowoo1234!";

        try {
            Class.forName("com.microsoft.sqlserver.jdbc.SQLServerDriver");
            System.out.println("Connecting to DWCMSTEST ...");

            try (Connection conn = DriverManager.getConnection(dbUrl, user, pass)) {
                System.out.println("Connected!");

                try (Statement stmt = conn.createStatement()) {

                    // 1. 현재 상태 확인
                    System.out.println("\n=== Before Fix ===");
                    ResultSet rs = stmt.executeQuery(
                        "SELECT PROD_CATEGORY, COUNT(*) AS cnt FROM DOI_CM_SYS_RESOURCE GROUP BY PROD_CATEGORY"
                    );
                    while (rs.next()) {
                        System.out.println("  DOI_CM_SYS_RESOURCE: " + rs.getString(1) + " = " + rs.getInt(2) + " rows");
                    }

                    rs = stmt.executeQuery(
                        "SELECT PROD_CATEGORY, COUNT(*) AS cnt FROM doi_cm_role_sys_resource GROUP BY PROD_CATEGORY"
                    );
                    while (rs.next()) {
                        System.out.println("  doi_cm_role_sys_resource: " + rs.getString(1) + " = " + rs.getInt(2) + " rows");
                    }

                    rs = stmt.executeQuery("SELECT PROD_CATEGORY FROM DOI_PROD_IN_MENU ORDER BY PROD_CATEGORY");
                    System.out.println("  DOI_PROD_IN_MENU categories:");
                    while (rs.next()) {
                        System.out.println("    " + rs.getString(1));
                    }

                    // 2. DOI_CM_SYS_RESOURCE: COST -> HQ
                    System.out.println("\n=== Fixing PROD_CATEGORY: COST -> HQ ===");

                    int updated1 = stmt.executeUpdate(
                        "UPDATE DOI_CM_SYS_RESOURCE SET PROD_CATEGORY = 'HQ' WHERE PROD_CATEGORY = 'COST'"
                    );
                    System.out.println("  DOI_CM_SYS_RESOURCE updated: " + updated1 + " rows");

                    // 3. doi_cm_role_sys_resource: COST -> HQ
                    // Need to handle PK conflicts - delete existing HQ first if any, then update COST->HQ
                    int deleted = stmt.executeUpdate(
                        "DELETE FROM doi_cm_role_sys_resource WHERE PROD_CATEGORY = 'HQ'"
                    );
                    System.out.println("  Deleted existing HQ role-menu mappings: " + deleted);

                    int updated2 = stmt.executeUpdate(
                        "UPDATE doi_cm_role_sys_resource SET PROD_CATEGORY = 'HQ' WHERE PROD_CATEGORY = 'COST'"
                    );
                    System.out.println("  doi_cm_role_sys_resource updated: " + updated2 + " rows");

                    // 4. DOI_PROD_IN_MENU - COST행 삭제 (HQ/VN만 남김)
                    stmt.executeUpdate("DELETE FROM DOI_PROD_IN_MENU WHERE PROD_CATEGORY = 'COST'");
                    System.out.println("  Removed COST from DOI_PROD_IN_MENU (HQ/VN만 유지)");

                    // 5. 결과 확인
                    System.out.println("\n=== After Fix ===");
                    rs = stmt.executeQuery(
                        "SELECT PROD_CATEGORY, COUNT(*) AS cnt FROM DOI_CM_SYS_RESOURCE GROUP BY PROD_CATEGORY"
                    );
                    while (rs.next()) {
                        System.out.println("  DOI_CM_SYS_RESOURCE: " + rs.getString(1) + " = " + rs.getInt(2) + " rows");
                    }

                    rs = stmt.executeQuery(
                        "SELECT PROD_CATEGORY, COUNT(*) AS cnt FROM doi_cm_role_sys_resource GROUP BY PROD_CATEGORY"
                    );
                    while (rs.next()) {
                        System.out.println("  doi_cm_role_sys_resource: " + rs.getString(1) + " = " + rs.getInt(2) + " rows");
                    }

                    rs = stmt.executeQuery("SELECT PROD_CATEGORY FROM DOI_PROD_IN_MENU ORDER BY PROD_CATEGORY");
                    System.out.println("  DOI_PROD_IN_MENU categories:");
                    while (rs.next()) {
                        System.out.println("    " + rs.getString(1));
                    }

                    // 6. 로그인 시뮬레이션: SYSADMIN이 HQ로 메뉴 조회
                    System.out.println("\n=== Login Simulation (SYSADMIN / HQ) ===");
                    rs = stmt.executeQuery(
                        "SELECT a.prod_category FROM DOI_PROD_IN_MENU a " +
                        "LEFT OUTER JOIN doi_cm_user b ON (b.USER_ID = 'SYSADMIN') " +
                        "WHERE CASE WHEN a.prod_category = 'HQ' THEN b.utg " +
                        "WHEN a.prod_category = 'VN' THEN b.ITG END = 'Y' " +
                        "ORDER BY CASE WHEN prod_category = 'HQ' THEN 1 WHEN prod_category = 'VN' THEN 2 ELSE 99 END"
                    );
                    System.out.println("  Available categories for SYSADMIN:");
                    while (rs.next()) {
                        System.out.println("    " + rs.getString(1));
                    }

                    rs = stmt.executeQuery(
                        "WITH auth_sys_resc AS ( " +
                        "  SELECT UPPER_SYS_RESOURCE_ID, SYS_RESOURCE_ID " +
                        "  FROM doi_cm_role_sys_resource a " +
                        "  INNER JOIN doi_cm_user_ROLE b ON (a.ROLE_ID = b.ROLE_ID) " +
                        "  WHERE b.user_id = 'SYSADMIN' AND a.prod_category = 'HQ' " +
                        "  GROUP BY UPPER_SYS_RESOURCE_ID, SYS_RESOURCE_ID " +
                        ") " +
                        "SELECT COUNT(*) AS menu_count FROM auth_sys_resc"
                    );
                    rs.next();
                    System.out.println("  Authorized menus for SYSADMIN/HQ: " + rs.getInt(1));

                    System.out.println("\n========================================");
                    System.out.println("FIX COMPLETE! Menus should now appear.");
                    System.out.println("========================================");
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
