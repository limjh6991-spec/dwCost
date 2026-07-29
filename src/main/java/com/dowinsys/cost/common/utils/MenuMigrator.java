package com.dowinsys.cost.common.utils;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * 운영DB(172.16.0.208 / 도우제조MES시스템DB)에서 메뉴·역할·권한 데이터를 
 * 개발DB(10.100.40.17 / DWCMSTEST)로 복사하는 유틸
 */
public class MenuMigrator {

    static final String SRC_URL = "jdbc:sqlserver://172.16.0.208:1433;databaseName=도우제조MES시스템DB;encrypt=true;trustServerCertificate=true";
    static final String SRC_USER = "bs";
    static final String SRC_PASS = "ehdndlstltm1!";

    static final String DST_URL = "jdbc:sqlserver://10.100.40.17:14233;databaseName=DWCMSTEST;encrypt=true;trustServerCertificate=true";
    static final String DST_USER = "cost";
    static final String DST_PASS = "Dowoo1234!";

    public static void main(String[] args) {
        try {
            Class.forName("com.microsoft.sqlserver.jdbc.SQLServerDriver");

            System.out.println("=== Connecting to SOURCE DB (172.16.0.208 / 도우제조MES시스템DB) ===");
            Connection srcConn = DriverManager.getConnection(SRC_URL, SRC_USER, SRC_PASS);
            System.out.println("Source connected!");

            System.out.println("\n=== Connecting to TARGET DB (10.100.40.17 / DWCMSTEST) ===");
            Connection dstConn = DriverManager.getConnection(DST_URL, DST_USER, DST_PASS);
            System.out.println("Target connected!");
            dstConn.setAutoCommit(false);

            // ==============================
            // 1. DOI_CM_SYS_RESOURCE 복사
            // ==============================
            System.out.println("\n=== 1. Migrating DOI_CM_SYS_RESOURCE ===");
            Statement srcStmt = srcConn.createStatement();

            // Clear target
            Statement dstStmt = dstConn.createStatement();
            int del1 = dstStmt.executeUpdate("DELETE FROM DOI_CM_SYS_RESOURCE");
            System.out.println("  Target cleared: " + del1 + " rows deleted");

            ResultSet rs = srcStmt.executeQuery(
                "SELECT PROD_CATEGORY, SYS_RESOURCE_ID, SYS_RESOURCE_NAME, UPPER_SYS_RESOURCE_ID, " +
                "SYS_RESOURCE_TYPE_CODE_ID, DESCRIPTION, SEQ, URL, INIT_DT, INIT_USER, DEL_YN " +
                "FROM DOI_CM_SYS_RESOURCE"
            );

            PreparedStatement insertMenu = dstConn.prepareStatement(
                "INSERT INTO DOI_CM_SYS_RESOURCE (PROD_CATEGORY, SYS_RESOURCE_ID, SYS_RESOURCE_NAME, " +
                "UPPER_SYS_RESOURCE_ID, SYS_RESOURCE_TYPE_CODE_ID, DESCRIPTION, SEQ, URL, INIT_DT, INIT_USER, DEL_YN) " +
                "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"
            );

            int menuCount = 0;
            while (rs.next()) {
                insertMenu.setString(1, rs.getString("PROD_CATEGORY"));
                insertMenu.setString(2, rs.getString("SYS_RESOURCE_ID"));
                insertMenu.setNString(3, rs.getNString("SYS_RESOURCE_NAME"));
                insertMenu.setString(4, rs.getString("UPPER_SYS_RESOURCE_ID"));
                insertMenu.setString(5, rs.getString("SYS_RESOURCE_TYPE_CODE_ID"));
                insertMenu.setNString(6, rs.getNString("DESCRIPTION"));
                insertMenu.setObject(7, rs.getObject("SEQ"));
                insertMenu.setString(8, rs.getString("URL"));
                insertMenu.setTimestamp(9, rs.getTimestamp("INIT_DT"));
                insertMenu.setString(10, rs.getString("INIT_USER"));
                insertMenu.setString(11, rs.getString("DEL_YN"));
                insertMenu.addBatch();
                menuCount++;
                if (menuCount % 100 == 0) insertMenu.executeBatch();
            }
            insertMenu.executeBatch();
            dstConn.commit();
            System.out.println("  Copied " + menuCount + " menu rows");

            // ==============================
            // 2. DOI_CM_ROLE 복사
            // ==============================
            System.out.println("\n=== 2. Migrating DOI_CM_ROLE ===");
            del1 = dstStmt.executeUpdate("DELETE FROM DOI_CM_ROLE");
            System.out.println("  Target cleared: " + del1 + " rows deleted");

            rs = srcStmt.executeQuery("SELECT ROLE_ID, ROLE_NAME, DESCRIPTION, INIT_DT, INIT_USER, DEL_YN FROM DOI_CM_ROLE");
            PreparedStatement insertRole = dstConn.prepareStatement(
                "INSERT INTO DOI_CM_ROLE (ROLE_ID, ROLE_NAME, DESCRIPTION, INIT_DT, INIT_USER, DEL_YN) VALUES (?, ?, ?, ?, ?, ?)"
            );
            int roleCount = 0;
            while (rs.next()) {
                insertRole.setString(1, rs.getString("ROLE_ID"));
                insertRole.setNString(2, rs.getNString("ROLE_NAME"));
                insertRole.setNString(3, rs.getNString("DESCRIPTION"));
                insertRole.setTimestamp(4, rs.getTimestamp("INIT_DT"));
                insertRole.setString(5, rs.getString("INIT_USER"));
                insertRole.setString(6, rs.getString("DEL_YN"));
                insertRole.addBatch();
                roleCount++;
            }
            insertRole.executeBatch();
            dstConn.commit();
            System.out.println("  Copied " + roleCount + " role rows");

            // ==============================
            // 3. doi_cm_role_sys_resource 복사
            // ==============================
            System.out.println("\n=== 3. Migrating doi_cm_role_sys_resource ===");
            del1 = dstStmt.executeUpdate("DELETE FROM doi_cm_role_sys_resource");
            System.out.println("  Target cleared: " + del1 + " rows deleted");

            rs = srcStmt.executeQuery(
                "SELECT ROLE_ID, PROD_CATEGORY, UPPER_SYS_RESOURCE_ID, SYS_RESOURCE_ID, " +
                "SYS_RESOURCE_TYPE_CODE_ID, INIT_DT, INIT_USER FROM doi_cm_role_sys_resource"
            );
            PreparedStatement insertRoleMenu = dstConn.prepareStatement(
                "INSERT INTO doi_cm_role_sys_resource (ROLE_ID, PROD_CATEGORY, UPPER_SYS_RESOURCE_ID, " +
                "SYS_RESOURCE_ID, SYS_RESOURCE_TYPE_CODE_ID, INIT_DT, INIT_USER) VALUES (?, ?, ?, ?, ?, ?, ?)"
            );
            int roleMenuCount = 0;
            while (rs.next()) {
                insertRoleMenu.setString(1, rs.getString("ROLE_ID"));
                insertRoleMenu.setString(2, rs.getString("PROD_CATEGORY"));
                insertRoleMenu.setString(3, rs.getString("UPPER_SYS_RESOURCE_ID"));
                insertRoleMenu.setString(4, rs.getString("SYS_RESOURCE_ID"));
                insertRoleMenu.setString(5, rs.getString("SYS_RESOURCE_TYPE_CODE_ID"));
                insertRoleMenu.setTimestamp(6, rs.getTimestamp("INIT_DT"));
                insertRoleMenu.setString(7, rs.getString("INIT_USER"));
                insertRoleMenu.addBatch();
                roleMenuCount++;
                if (roleMenuCount % 100 == 0) insertRoleMenu.executeBatch();
            }
            insertRoleMenu.executeBatch();
            dstConn.commit();
            System.out.println("  Copied " + roleMenuCount + " role-menu rows");

            // ==============================
            // 4. doi_cm_user 복사 (기존 유지 + 소스에서 추가)
            // ==============================
            System.out.println("\n=== 4. Migrating doi_cm_user ===");
            rs = srcStmt.executeQuery(
                "SELECT USER_ID, PASSWORD, USER_NAME, DEPT_NAME, DEPT_CODE, POSITION_NAME, POSITION_CODE, " +
                "UTG, ITG, INIT_DT, INIT_USER, MODI_DT, MODI_USER, DEL_YN FROM doi_cm_user"
            );
            PreparedStatement upsertUser = dstConn.prepareStatement(
                "IF NOT EXISTS (SELECT 1 FROM doi_cm_user WHERE USER_ID = ?) " +
                "INSERT INTO doi_cm_user (USER_ID, PASSWORD, USER_NAME, DEPT_NAME, DEPT_CODE, POSITION_NAME, POSITION_CODE, " +
                "UTG, ITG, INIT_DT, INIT_USER, DEL_YN) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?) " +
                "ELSE UPDATE doi_cm_user SET PASSWORD=?, USER_NAME=?, UTG=?, ITG=?, DEL_YN=? WHERE USER_ID=?"
            );
            int userCount = 0;
            while (rs.next()) {
                String uid = rs.getString("USER_ID");
                String pwd = rs.getString("PASSWORD");
                String uname = rs.getNString("USER_NAME");
                String dname = rs.getNString("DEPT_NAME");
                String dcode = rs.getString("DEPT_CODE");
                String pname = rs.getNString("POSITION_NAME");
                String pcode = rs.getString("POSITION_CODE");
                String utg = rs.getString("UTG");
                String itg = rs.getString("ITG");
                Timestamp idt = rs.getTimestamp("INIT_DT");
                String iuser = rs.getString("INIT_USER");
                String delyn = rs.getString("DEL_YN");

                upsertUser.setString(1, uid);     // EXISTS check
                upsertUser.setString(2, uid);     // INSERT USER_ID
                upsertUser.setString(3, pwd);
                upsertUser.setNString(4, uname);
                upsertUser.setNString(5, dname);
                upsertUser.setString(6, dcode);
                upsertUser.setNString(7, pname);
                upsertUser.setString(8, pcode);
                upsertUser.setString(9, utg);
                upsertUser.setString(10, itg);
                upsertUser.setTimestamp(11, idt);
                upsertUser.setString(12, iuser);
                upsertUser.setString(13, delyn);
                upsertUser.setString(14, pwd);    // UPDATE PASSWORD
                upsertUser.setNString(15, uname); // UPDATE USER_NAME
                upsertUser.setString(16, utg);    // UPDATE UTG
                upsertUser.setString(17, itg);    // UPDATE ITG
                upsertUser.setString(18, delyn);  // UPDATE DEL_YN
                upsertUser.setString(19, uid);    // UPDATE WHERE

                upsertUser.addBatch();
                userCount++;
            }
            upsertUser.executeBatch();
            dstConn.commit();
            System.out.println("  Upserted " + userCount + " user rows");

            // Ensure SYSADMIN/1111 exists with both UTG=Y, ITG=Y
            dstStmt.executeUpdate(
                "IF NOT EXISTS (SELECT 1 FROM doi_cm_user WHERE USER_ID = 'SYSADMIN') " +
                "INSERT INTO doi_cm_user (USER_ID, PASSWORD, USER_NAME, UTG, ITG, DEL_YN) " +
                "VALUES ('SYSADMIN', '1111', N'시스템관리자', 'Y', 'Y', 'N') " +
                "ELSE UPDATE doi_cm_user SET PASSWORD='1111', UTG='Y', ITG='Y', DEL_YN='N' WHERE USER_ID='SYSADMIN'"
            );
            System.out.println("  Ensured SYSADMIN/1111 (UTG=Y, ITG=Y)");

            // Ensure VINA account
            dstStmt.executeUpdate(
                "IF NOT EXISTS (SELECT 1 FROM doi_cm_user WHERE USER_ID = 'VINA') " +
                "INSERT INTO doi_cm_user (USER_ID, PASSWORD, USER_NAME, UTG, ITG, DEL_YN) " +
                "VALUES ('VINA', '1111', N'비나법인', 'N', 'Y', 'N') " +
                "ELSE UPDATE doi_cm_user SET PASSWORD='1111', UTG='N', ITG='Y', DEL_YN='N' WHERE USER_ID='VINA'"
            );
            System.out.println("  Ensured VINA/1111 (UTG=N, ITG=Y)");
            dstConn.commit();

            // ==============================
            // 5. doi_cm_user_ROLE 복사
            // ==============================
            System.out.println("\n=== 5. Migrating doi_cm_user_ROLE ===");
            del1 = dstStmt.executeUpdate("DELETE FROM doi_cm_user_ROLE");
            System.out.println("  Target cleared: " + del1 + " rows deleted");

            rs = srcStmt.executeQuery("SELECT USER_ID, ROLE_ID, INIT_DT, INIT_USER FROM doi_cm_user_ROLE");
            PreparedStatement insertUserRole = dstConn.prepareStatement(
                "INSERT INTO doi_cm_user_ROLE (USER_ID, ROLE_ID, INIT_DT, INIT_USER) VALUES (?, ?, ?, ?)"
            );
            int userRoleCount = 0;
            while (rs.next()) {
                insertUserRole.setString(1, rs.getString("USER_ID"));
                insertUserRole.setString(2, rs.getString("ROLE_ID"));
                insertUserRole.setTimestamp(3, rs.getTimestamp("INIT_DT"));
                insertUserRole.setString(4, rs.getString("INIT_USER"));
                insertUserRole.addBatch();
                userRoleCount++;
            }
            insertUserRole.executeBatch();

            // Add SYSADMIN and VINA role mappings
            String[][] extraRoles = {
                {"SYSADMIN", "ROLE_ADMIN"}, {"SYSADMIN", "ROLE_USER"},
                {"VINA", "ROLE_ADMIN"}, {"VINA", "ROLE_USER"}
            };
            for (String[] ur : extraRoles) {
                try {
                    dstConn.createStatement().executeUpdate(
                        "IF NOT EXISTS (SELECT 1 FROM doi_cm_user_ROLE WHERE USER_ID='" + ur[0] + "' AND ROLE_ID='" + ur[1] + "') " +
                        "INSERT INTO doi_cm_user_ROLE (USER_ID, ROLE_ID) VALUES ('" + ur[0] + "', '" + ur[1] + "')"
                    );
                } catch (Exception ignore) {}
            }
            dstConn.commit();
            System.out.println("  Copied " + userRoleCount + " user-role rows + SYSADMIN/VINA extras");

            // ==============================
            // 6. DOI_PROD_IN_MENU 복사
            // ==============================
            System.out.println("\n=== 6. Migrating DOI_PROD_IN_MENU ===");
            del1 = dstStmt.executeUpdate("DELETE FROM DOI_PROD_IN_MENU");
            rs = srcStmt.executeQuery("SELECT PROD_CATEGORY, PROCESS_ID, REVISION FROM DOI_PROD_IN_MENU");
            int prodCount = 0;
            while (rs.next()) {
                dstStmt.executeUpdate(
                    "INSERT INTO DOI_PROD_IN_MENU (PROD_CATEGORY, PROCESS_ID, REVISION) VALUES ('" +
                    rs.getString(1) + "', '" + rs.getString(2) + "', '" + rs.getString(3) + "')"
                );
                prodCount++;
            }
            dstConn.commit();
            System.out.println("  Copied " + prodCount + " prod_in_menu rows");

            // ==============================
            // 7. 검증
            // ==============================
            System.out.println("\n=== Final Verification on TARGET ===");
            rs = dstStmt.executeQuery("SELECT PROD_CATEGORY, COUNT(*) cnt FROM DOI_CM_SYS_RESOURCE GROUP BY PROD_CATEGORY ORDER BY PROD_CATEGORY");
            while (rs.next()) System.out.println("  Menus [" + rs.getString(1) + "]: " + rs.getInt(2));

            rs = dstStmt.executeQuery("SELECT COUNT(*) cnt FROM DOI_CM_ROLE WHERE DEL_YN='N'");
            rs.next(); System.out.println("  Roles: " + rs.getInt(1));

            rs = dstStmt.executeQuery("SELECT PROD_CATEGORY, COUNT(*) cnt FROM doi_cm_role_sys_resource GROUP BY PROD_CATEGORY ORDER BY PROD_CATEGORY");
            while (rs.next()) System.out.println("  Role-Menu [" + rs.getString(1) + "]: " + rs.getInt(2));

            rs = dstStmt.executeQuery("SELECT USER_ID, USER_NAME, UTG, ITG FROM doi_cm_user WHERE DEL_YN='N'");
            System.out.println("  Active Users:");
            while (rs.next()) System.out.println("    " + rs.getString(1) + " (" + rs.getNString(2) + ") UTG=" + rs.getString(3) + " ITG=" + rs.getString(4));

            rs = dstStmt.executeQuery("SELECT PROD_CATEGORY FROM DOI_PROD_IN_MENU ORDER BY PROD_CATEGORY");
            System.out.print("  Sites: ");
            List<String> sites = new ArrayList<>();
            while (rs.next()) sites.add(rs.getString(1));
            System.out.println(String.join(", ", sites));

            // Login simulation
            System.out.println("\n=== Login Simulation ===");
            for (String testUser : new String[]{"SYSADMIN", "VINA"}) {
                rs = dstStmt.executeQuery(
                    "SELECT a.prod_category FROM DOI_PROD_IN_MENU a " +
                    "LEFT OUTER JOIN doi_cm_user b ON (b.USER_ID = '" + testUser + "') " +
                    "WHERE CASE WHEN a.prod_category = 'HQ' THEN b.utg WHEN a.prod_category = 'VN' THEN b.ITG END = 'Y' " +
                    "ORDER BY CASE WHEN prod_category = 'HQ' THEN 1 WHEN prod_category = 'VN' THEN 2 ELSE 99 END"
                );
                List<String> cats = new ArrayList<>();
                while (rs.next()) cats.add(rs.getString(1));
                System.out.println("  " + testUser + " sites: " + String.join(", ", cats));

                for (String cat : cats) {
                    rs = dstStmt.executeQuery(
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

            System.out.println("\n========================================");
            System.out.println("MIGRATION COMPLETE!");
            System.out.println("========================================");

            srcConn.close();
            dstConn.close();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
