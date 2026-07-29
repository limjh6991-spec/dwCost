package com.dowinsys.cost.common.utils;

import java.sql.*;
import java.util.*;

/**
 * VN 메뉴 누락 분석 및 HQ 메뉴를 VN으로 복사
 */
public class FixVnMenus {

    public static void main(String[] args) {
        String dbUrl = "jdbc:sqlserver://10.100.40.17:14233;databaseName=DWCMSTEST;encrypt=true;trustServerCertificate=true";
        String user = "cost";
        String pass = "Dowoo1234!";

        try {
            Class.forName("com.microsoft.sqlserver.jdbc.SQLServerDriver");
            try (Connection conn = DriverManager.getConnection(dbUrl, user, pass)) {
                System.out.println("Connected!");
                Statement stmt = conn.createStatement();

                // 1. HQ vs VN 메뉴 비교
                System.out.println("\n=== HQ Menus ===");
                ResultSet rs = stmt.executeQuery(
                    "SELECT SYS_RESOURCE_ID, SYS_RESOURCE_NAME, UPPER_SYS_RESOURCE_ID, SEQ, URL " +
                    "FROM DOI_CM_SYS_RESOURCE WHERE PROD_CATEGORY='HQ' AND DEL_YN='N' ORDER BY SYS_RESOURCE_ID"
                );
                List<String> hqMenuIds = new ArrayList<>();
                while (rs.next()) {
                    hqMenuIds.add(rs.getString("SYS_RESOURCE_ID"));
                    System.out.println("  " + rs.getString("SYS_RESOURCE_ID") + " | " + rs.getNString("SYS_RESOURCE_NAME") +
                        " | upper=" + rs.getString("UPPER_SYS_RESOURCE_ID"));
                }
                System.out.println("  Total: " + hqMenuIds.size());

                System.out.println("\n=== VN Menus ===");
                rs = stmt.executeQuery(
                    "SELECT SYS_RESOURCE_ID, SYS_RESOURCE_NAME, UPPER_SYS_RESOURCE_ID, SEQ, URL " +
                    "FROM DOI_CM_SYS_RESOURCE WHERE PROD_CATEGORY='VN' AND DEL_YN='N' ORDER BY SYS_RESOURCE_ID"
                );
                List<String> vnMenuIds = new ArrayList<>();
                while (rs.next()) {
                    vnMenuIds.add(rs.getString("SYS_RESOURCE_ID"));
                    System.out.println("  " + rs.getString("SYS_RESOURCE_ID") + " | " + rs.getNString("SYS_RESOURCE_NAME") +
                        " | upper=" + rs.getString("UPPER_SYS_RESOURCE_ID"));
                }
                System.out.println("  Total: " + vnMenuIds.size());

                // 2. HQ에는 있지만 VN에 없는 메뉴
                System.out.println("\n=== Missing in VN (exist in HQ but not VN) ===");
                List<String> missing = new ArrayList<>();
                for (String id : hqMenuIds) {
                    if (!vnMenuIds.contains(id)) {
                        missing.add(id);
                    }
                }
                rs = stmt.executeQuery(
                    "SELECT SYS_RESOURCE_ID, SYS_RESOURCE_NAME, UPPER_SYS_RESOURCE_ID " +
                    "FROM DOI_CM_SYS_RESOURCE WHERE PROD_CATEGORY='HQ' AND DEL_YN='N' " +
                    "AND SYS_RESOURCE_ID NOT IN (SELECT SYS_RESOURCE_ID FROM DOI_CM_SYS_RESOURCE WHERE PROD_CATEGORY='VN') " +
                    "ORDER BY SYS_RESOURCE_ID"
                );
                while (rs.next()) {
                    System.out.println("  " + rs.getString("SYS_RESOURCE_ID") + " | " + rs.getNString("SYS_RESOURCE_NAME") +
                        " | upper=" + rs.getString("UPPER_SYS_RESOURCE_ID"));
                }
                System.out.println("  Missing count: " + missing.size());

                // 3. HQ 메뉴를 VN으로 복사 (VN에 없는 것만)
                System.out.println("\n=== Copying HQ menus to VN ===");
                int copied = stmt.executeUpdate(
                    "INSERT INTO DOI_CM_SYS_RESOURCE (PROD_CATEGORY, SYS_RESOURCE_ID, SYS_RESOURCE_NAME, " +
                    "UPPER_SYS_RESOURCE_ID, SYS_RESOURCE_TYPE_CODE_ID, DESCRIPTION, SEQ, URL, INIT_DT, INIT_USER, DEL_YN) " +
                    "SELECT 'VN', SYS_RESOURCE_ID, SYS_RESOURCE_NAME, UPPER_SYS_RESOURCE_ID, " +
                    "SYS_RESOURCE_TYPE_CODE_ID, DESCRIPTION, SEQ, URL, GETDATE(), 'SYSTEM', DEL_YN " +
                    "FROM DOI_CM_SYS_RESOURCE WHERE PROD_CATEGORY='HQ' " +
                    "AND SYS_RESOURCE_ID NOT IN (SELECT SYS_RESOURCE_ID FROM DOI_CM_SYS_RESOURCE WHERE PROD_CATEGORY='VN')"
                );
                System.out.println("  Copied " + copied + " HQ menus to VN");

                // 4. VN 역할-메뉴 매핑도 복사
                System.out.println("\n=== Copying HQ role-menu mappings to VN ===");
                int roleCopied = stmt.executeUpdate(
                    "INSERT INTO doi_cm_role_sys_resource (ROLE_ID, PROD_CATEGORY, UPPER_SYS_RESOURCE_ID, " +
                    "SYS_RESOURCE_ID, SYS_RESOURCE_TYPE_CODE_ID, INIT_DT, INIT_USER) " +
                    "SELECT ROLE_ID, 'VN', UPPER_SYS_RESOURCE_ID, SYS_RESOURCE_ID, " +
                    "SYS_RESOURCE_TYPE_CODE_ID, GETDATE(), 'SYSTEM' " +
                    "FROM doi_cm_role_sys_resource WHERE PROD_CATEGORY='HQ' " +
                    "AND NOT EXISTS (SELECT 1 FROM doi_cm_role_sys_resource v " +
                    "WHERE v.PROD_CATEGORY='VN' AND v.ROLE_ID=doi_cm_role_sys_resource.ROLE_ID " +
                    "AND v.SYS_RESOURCE_ID=doi_cm_role_sys_resource.SYS_RESOURCE_ID)"
                );
                System.out.println("  Copied " + roleCopied + " role-menu mappings to VN");

                // 5. 최종 검증
                System.out.println("\n=== Final Verification ===");
                rs = stmt.executeQuery("SELECT PROD_CATEGORY, COUNT(*) cnt FROM DOI_CM_SYS_RESOURCE WHERE DEL_YN='N' GROUP BY PROD_CATEGORY");
                while (rs.next()) System.out.println("  Menus [" + rs.getString(1) + "]: " + rs.getInt(2));

                rs = stmt.executeQuery("SELECT PROD_CATEGORY, COUNT(*) cnt FROM doi_cm_role_sys_resource GROUP BY PROD_CATEGORY");
                while (rs.next()) System.out.println("  Role-Menu [" + rs.getString(1) + "]: " + rs.getInt(2));

                // Login simulation
                for (String testUser : new String[]{"SYSADMIN", "VINA"}) {
                    rs = stmt.executeQuery(
                        "SELECT a.prod_category FROM DOI_PROD_IN_MENU a " +
                        "LEFT OUTER JOIN doi_cm_user b ON (b.USER_ID = '" + testUser + "') " +
                        "WHERE CASE WHEN a.prod_category = 'HQ' THEN b.utg WHEN a.prod_category = 'VN' THEN b.ITG END = 'Y' " +
                        "ORDER BY CASE WHEN prod_category = 'HQ' THEN 1 WHEN prod_category = 'VN' THEN 2 ELSE 99 END"
                    );
                    List<String> cats = new ArrayList<>();
                    while (rs.next()) cats.add(rs.getString(1));

                    for (String cat : cats) {
                        rs = stmt.executeQuery(
                            "WITH auth_sys_resc AS ( " +
                            "SELECT UPPER_SYS_RESOURCE_ID, SYS_RESOURCE_ID FROM doi_cm_role_sys_resource a " +
                            "INNER JOIN doi_cm_user_ROLE b ON (a.ROLE_ID = b.ROLE_ID) " +
                            "WHERE b.user_id = '" + testUser + "' AND a.prod_category = '" + cat + "' " +
                            "GROUP BY UPPER_SYS_RESOURCE_ID, SYS_RESOURCE_ID) " +
                            "SELECT COUNT(*) AS cnt FROM auth_sys_resc"
                        );
                        rs.next();
                        System.out.println("  " + testUser + "/" + cat + ": " + rs.getInt(1) + " menus");
                    }
                }

                System.out.println("\nDONE!");
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
