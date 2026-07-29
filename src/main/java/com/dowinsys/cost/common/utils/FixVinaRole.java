package com.dowinsys.cost.common.utils;

import java.sql.*;
import java.util.*;

/**
 * VINA 계정에 VN 메뉴 접근 권한 부여
 * - 운영DB의 역할 구조를 확인하고 VINA 계정에 적절한 역할을 매핑
 */
public class FixVinaRole {

    public static void main(String[] args) {
        String dbUrl = "jdbc:sqlserver://10.100.40.17:14233;databaseName=DWCMSTEST;encrypt=true;trustServerCertificate=true";
        String user = "cost";
        String pass = "Dowoo1234!";

        try {
            Class.forName("com.microsoft.sqlserver.jdbc.SQLServerDriver");

            try (Connection conn = DriverManager.getConnection(dbUrl, user, pass)) {
                System.out.println("Connected to DWCMSTEST!");
                Statement stmt = conn.createStatement();

                // 1. 현재 역할 목록 확인
                System.out.println("\n=== Roles ===");
                ResultSet rs = stmt.executeQuery("SELECT ROLE_ID, ROLE_NAME, DEL_YN FROM DOI_CM_ROLE");
                List<String> allRoles = new ArrayList<>();
                while (rs.next()) {
                    String rid = rs.getString("ROLE_ID");
                    allRoles.add(rid);
                    System.out.println("  " + rid + " (" + rs.getNString("ROLE_NAME") + ") del=" + rs.getString("DEL_YN"));
                }

                // 2. 역할별 VN 메뉴 권한 확인
                System.out.println("\n=== Roles with VN menu access ===");
                rs = stmt.executeQuery(
                    "SELECT ROLE_ID, COUNT(*) AS cnt FROM doi_cm_role_sys_resource " +
                    "WHERE PROD_CATEGORY = 'VN' GROUP BY ROLE_ID ORDER BY cnt DESC"
                );
                List<String> vnRoles = new ArrayList<>();
                while (rs.next()) {
                    String rid = rs.getString("ROLE_ID");
                    vnRoles.add(rid);
                    System.out.println("  " + rid + " -> " + rs.getInt("cnt") + " VN menus");
                }

                // 3. 역할별 HQ 메뉴 권한 확인
                System.out.println("\n=== Roles with HQ menu access ===");
                rs = stmt.executeQuery(
                    "SELECT ROLE_ID, COUNT(*) AS cnt FROM doi_cm_role_sys_resource " +
                    "WHERE PROD_CATEGORY = 'HQ' GROUP BY ROLE_ID ORDER BY cnt DESC"
                );
                while (rs.next()) {
                    System.out.println("  " + rs.getString("ROLE_ID") + " -> " + rs.getInt("cnt") + " HQ menus");
                }

                // 4. VINA 계정의 현재 역할 확인
                System.out.println("\n=== VINA current roles ===");
                rs = stmt.executeQuery("SELECT ROLE_ID FROM doi_cm_user_ROLE WHERE USER_ID = 'VINA'");
                List<String> vinaRoles = new ArrayList<>();
                while (rs.next()) {
                    String rid = rs.getString("ROLE_ID");
                    vinaRoles.add(rid);
                    System.out.println("  " + rid);
                }

                // 5. SYSADMIN 계정의 현재 역할 확인
                System.out.println("\n=== SYSADMIN current roles ===");
                rs = stmt.executeQuery("SELECT ROLE_ID FROM doi_cm_user_ROLE WHERE USER_ID = 'SYSADMIN'");
                List<String> sysadminRoles = new ArrayList<>();
                while (rs.next()) {
                    String rid = rs.getString("ROLE_ID");
                    sysadminRoles.add(rid);
                    System.out.println("  " + rid);
                }

                // 6. VINA에 모든 역할 매핑 (VN 메뉴 접근을 위해)
                System.out.println("\n=== Assigning ALL roles to VINA ===");
                for (String role : allRoles) {
                    if (!vinaRoles.contains(role)) {
                        stmt.executeUpdate(
                            "INSERT INTO doi_cm_user_ROLE (USER_ID, ROLE_ID) VALUES ('VINA', '" + role + "')"
                        );
                        System.out.println("  Added: VINA -> " + role);
                    } else {
                        System.out.println("  Already: VINA -> " + role);
                    }
                }

                // 7. SYSADMIN에도 모든 역할 매핑
                System.out.println("\n=== Assigning ALL roles to SYSADMIN ===");
                for (String role : allRoles) {
                    if (!sysadminRoles.contains(role)) {
                        stmt.executeUpdate(
                            "INSERT INTO doi_cm_user_ROLE (USER_ID, ROLE_ID) VALUES ('SYSADMIN', '" + role + "')"
                        );
                        System.out.println("  Added: SYSADMIN -> " + role);
                    } else {
                        System.out.println("  Already: SYSADMIN -> " + role);
                    }
                }

                // 8. 검증
                System.out.println("\n=== Verification ===");
                for (String testUser : new String[]{"SYSADMIN", "VINA"}) {
                    rs = stmt.executeQuery(
                        "SELECT a.prod_category FROM DOI_PROD_IN_MENU a " +
                        "LEFT OUTER JOIN doi_cm_user b ON (b.USER_ID = '" + testUser + "') " +
                        "WHERE CASE WHEN a.prod_category = 'HQ' THEN b.utg WHEN a.prod_category = 'VN' THEN b.ITG END = 'Y' " +
                        "ORDER BY CASE WHEN prod_category = 'HQ' THEN 1 WHEN prod_category = 'VN' THEN 2 ELSE 99 END"
                    );
                    List<String> cats = new ArrayList<>();
                    while (rs.next()) cats.add(rs.getString(1));
                    System.out.println("  " + testUser + " sites: " + String.join(", ", cats));

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
                        System.out.println("    " + cat + " authorized menus: " + rs.getInt(1));
                    }
                }

                System.out.println("\nDONE!");
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
