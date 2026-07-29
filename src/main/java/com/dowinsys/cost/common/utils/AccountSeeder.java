package com.dowinsys.cost.common.utils;

import java.sql.*;

/**
 * DWCMSTEST DB 초기 계정 및 메뉴/권한 데이터 생성
 * - SYSADMIN / 1111 계정
 * - 비나(VN) 계정
 * - 필수 메뉴/역할/권한 데이터
 */
public class AccountSeeder {

    public static void main(String[] args) {
        String dbUrl = "jdbc:sqlserver://10.100.40.17:14233;databaseName=DWCMSTEST;encrypt=true;trustServerCertificate=true";
        String user = "cost";
        String pass = "Dowoo1234!";

        try {
            Class.forName("com.microsoft.sqlserver.jdbc.SQLServerDriver");
            System.out.println("Connecting to DWCMSTEST on 10.100.40.17:14233 ...");

            try (Connection conn = DriverManager.getConnection(dbUrl, user, pass)) {
                System.out.println("Connected successfully!");
                conn.setAutoCommit(false);

                try (Statement stmt = conn.createStatement()) {

                    // ============================================
                    // 1. 테이블 존재 여부 확인 / 생성
                    // ============================================
                    System.out.println("\n=== Step 1: Checking/Creating tables ===");

                    // doi_cm_user
                    stmt.execute(
                        "IF OBJECT_ID('dbo.doi_cm_user', 'U') IS NULL " +
                        "CREATE TABLE dbo.doi_cm_user (" +
                        "    USER_ID NVARCHAR(50) NOT NULL PRIMARY KEY, " +
                        "    PASSWORD NVARCHAR(200) NULL, " +
                        "    USER_NAME NVARCHAR(100) NULL, " +
                        "    DEPT_NAME NVARCHAR(100) NULL, " +
                        "    DEPT_CODE NVARCHAR(50) NULL, " +
                        "    POSITION_NAME NVARCHAR(100) NULL, " +
                        "    POSITION_CODE NVARCHAR(50) NULL, " +
                        "    UTG VARCHAR(1) DEFAULT 'N', " +
                        "    ITG VARCHAR(1) DEFAULT 'N', " +
                        "    INIT_DT DATETIME DEFAULT GETDATE(), " +
                        "    INIT_USER NVARCHAR(50) NULL, " +
                        "    MODI_DT DATETIME NULL, " +
                        "    MODI_USER NVARCHAR(50) NULL, " +
                        "    DEL_YN VARCHAR(1) DEFAULT 'N' " +
                        ")"
                    );
                    System.out.println("  doi_cm_user: OK");

                    // DOI_CM_ROLE
                    stmt.execute(
                        "IF OBJECT_ID('dbo.DOI_CM_ROLE', 'U') IS NULL " +
                        "CREATE TABLE dbo.DOI_CM_ROLE (" +
                        "    ROLE_ID NVARCHAR(50) NOT NULL PRIMARY KEY, " +
                        "    ROLE_NAME NVARCHAR(100) NULL, " +
                        "    DESCRIPTION NVARCHAR(500) NULL, " +
                        "    INIT_DT DATETIME DEFAULT GETDATE(), " +
                        "    INIT_USER NVARCHAR(50) NULL, " +
                        "    DEL_YN VARCHAR(1) DEFAULT 'N' " +
                        ")"
                    );
                    System.out.println("  DOI_CM_ROLE: OK");

                    // doi_cm_user_ROLE
                    stmt.execute(
                        "IF OBJECT_ID('dbo.doi_cm_user_ROLE', 'U') IS NULL " +
                        "CREATE TABLE dbo.doi_cm_user_ROLE (" +
                        "    USER_ID NVARCHAR(50) NOT NULL, " +
                        "    ROLE_ID NVARCHAR(50) NOT NULL, " +
                        "    INIT_DT DATETIME DEFAULT GETDATE(), " +
                        "    INIT_USER NVARCHAR(50) NULL, " +
                        "    PRIMARY KEY (USER_ID, ROLE_ID) " +
                        ")"
                    );
                    System.out.println("  doi_cm_user_ROLE: OK");

                    // DOI_CM_SYS_RESOURCE
                    stmt.execute(
                        "IF OBJECT_ID('dbo.DOI_CM_SYS_RESOURCE', 'U') IS NULL " +
                        "CREATE TABLE dbo.DOI_CM_SYS_RESOURCE (" +
                        "    PROD_CATEGORY NVARCHAR(50) NOT NULL, " +
                        "    SYS_RESOURCE_ID NVARCHAR(50) NOT NULL, " +
                        "    SYS_RESOURCE_NAME NVARCHAR(200) NULL, " +
                        "    UPPER_SYS_RESOURCE_ID NVARCHAR(50) NULL, " +
                        "    SYS_RESOURCE_TYPE_CODE_ID VARCHAR(10) NULL, " +
                        "    DESCRIPTION NVARCHAR(500) NULL, " +
                        "    SEQ INT NULL, " +
                        "    URL NVARCHAR(500) NULL, " +
                        "    INIT_DT DATETIME DEFAULT GETDATE(), " +
                        "    INIT_USER NVARCHAR(50) NULL, " +
                        "    DEL_YN VARCHAR(1) DEFAULT 'N', " +
                        "    PRIMARY KEY (PROD_CATEGORY, SYS_RESOURCE_ID) " +
                        ")"
                    );
                    System.out.println("  DOI_CM_SYS_RESOURCE: OK");

                    // doi_cm_role_sys_resource
                    stmt.execute(
                        "IF OBJECT_ID('dbo.doi_cm_role_sys_resource', 'U') IS NULL " +
                        "CREATE TABLE dbo.doi_cm_role_sys_resource (" +
                        "    ROLE_ID NVARCHAR(50) NOT NULL, " +
                        "    PROD_CATEGORY NVARCHAR(50) NOT NULL, " +
                        "    UPPER_SYS_RESOURCE_ID NVARCHAR(50) NULL, " +
                        "    SYS_RESOURCE_ID NVARCHAR(50) NOT NULL, " +
                        "    SYS_RESOURCE_TYPE_CODE_ID VARCHAR(10) NULL, " +
                        "    INIT_DT DATETIME DEFAULT GETDATE(), " +
                        "    INIT_USER NVARCHAR(50) NULL, " +
                        "    PRIMARY KEY (ROLE_ID, PROD_CATEGORY, SYS_RESOURCE_ID) " +
                        ")"
                    );
                    System.out.println("  doi_cm_role_sys_resource: OK");

                    // DOI_PROD_IN_MENU
                    stmt.execute(
                        "IF OBJECT_ID('dbo.DOI_PROD_IN_MENU', 'U') IS NULL " +
                        "CREATE TABLE dbo.DOI_PROD_IN_MENU (" +
                        "    PROD_CATEGORY NVARCHAR(50) NOT NULL PRIMARY KEY, " +
                        "    PROCESS_ID NVARCHAR(50) NULL, " +
                        "    REVISION NVARCHAR(50) NULL " +
                        ")"
                    );
                    System.out.println("  DOI_PROD_IN_MENU: OK");

                    conn.commit();
                    System.out.println("  All tables verified/created.");

                    // ============================================
                    // 2. 역할(ROLE) 생성
                    // ============================================
                    System.out.println("\n=== Step 2: Creating Roles ===");
                    String[][] roles = {
                        {"ROLE_ADMIN", "관리자", "시스템 관리자 역할"},
                        {"ROLE_USER", "일반사용자", "일반 사용자 역할"},
                        {"ROLE_VN_ADMIN", "비나 관리자", "VINA 법인 관리자 역할"},
                        {"ROLE_VN_USER", "비나 사용자", "VINA 법인 사용자 역할"}
                    };
                    for (String[] r : roles) {
                        stmt.execute(
                            "IF NOT EXISTS (SELECT 1 FROM dbo.DOI_CM_ROLE WHERE ROLE_ID = '" + r[0] + "') " +
                            "INSERT INTO dbo.DOI_CM_ROLE (ROLE_ID, ROLE_NAME, DESCRIPTION, DEL_YN) " +
                            "VALUES ('" + r[0] + "', N'" + r[1] + "', N'" + r[2] + "', 'N')"
                        );
                        System.out.println("  Role: " + r[0] + " (" + r[1] + ")");
                    }
                    conn.commit();

                    // ============================================
                    // 3. 사용자 계정 생성
                    // ============================================
                    System.out.println("\n=== Step 3: Creating User Accounts ===");

                    // SYSADMIN / 1111 (본사+비나 모두 접근)
                    stmt.execute(
                        "IF NOT EXISTS (SELECT 1 FROM dbo.doi_cm_user WHERE USER_ID = 'SYSADMIN') " +
                        "INSERT INTO dbo.doi_cm_user (USER_ID, PASSWORD, USER_NAME, DEPT_NAME, DEPT_CODE, POSITION_NAME, UTG, ITG, DEL_YN) " +
                        "VALUES ('SYSADMIN', '1111', N'시스템관리자', N'시스템', 'SYS', N'관리자', 'Y', 'Y', 'N') " +
                        "ELSE UPDATE dbo.doi_cm_user SET PASSWORD='1111', UTG='Y', ITG='Y', DEL_YN='N' WHERE USER_ID='SYSADMIN'"
                    );
                    System.out.println("  SYSADMIN / 1111 (UTG=Y, ITG=Y) - 본사+비나 접근");

                    // VINA 전용 계정
                    stmt.execute(
                        "IF NOT EXISTS (SELECT 1 FROM dbo.doi_cm_user WHERE USER_ID = 'VINA') " +
                        "INSERT INTO dbo.doi_cm_user (USER_ID, PASSWORD, USER_NAME, DEPT_NAME, DEPT_CODE, POSITION_NAME, UTG, ITG, DEL_YN) " +
                        "VALUES ('VINA', '1111', N'비나법인', N'VINA', 'VN', N'담당자', 'N', 'Y', 'N') " +
                        "ELSE UPDATE dbo.doi_cm_user SET PASSWORD='1111', UTG='N', ITG='Y', DEL_YN='N' WHERE USER_ID='VINA'"
                    );
                    System.out.println("  VINA / 1111 (UTG=N, ITG=Y) - 비나 전용");

                    conn.commit();

                    // ============================================
                    // 4. 사용자-역할 매핑
                    // ============================================
                    System.out.println("\n=== Step 4: Assigning Roles to Users ===");
                    String[][] userRoles = {
                        {"SYSADMIN", "ROLE_ADMIN"},
                        {"SYSADMIN", "ROLE_USER"},
                        {"SYSADMIN", "ROLE_VN_ADMIN"},
                        {"SYSADMIN", "ROLE_VN_USER"},
                        {"VINA", "ROLE_VN_ADMIN"},
                        {"VINA", "ROLE_VN_USER"}
                    };
                    for (String[] ur : userRoles) {
                        stmt.execute(
                            "IF NOT EXISTS (SELECT 1 FROM dbo.doi_cm_user_ROLE WHERE USER_ID='" + ur[0] + "' AND ROLE_ID='" + ur[1] + "') " +
                            "INSERT INTO dbo.doi_cm_user_ROLE (USER_ID, ROLE_ID) VALUES ('" + ur[0] + "', '" + ur[1] + "')"
                        );
                        System.out.println("  " + ur[0] + " -> " + ur[1]);
                    }
                    conn.commit();

                    // ============================================
                    // 5. 사이트(PROD_CATEGORY) 등록
                    // ============================================
                    System.out.println("\n=== Step 5: Registering Site Categories ===");
                    stmt.execute(
                        "IF NOT EXISTS (SELECT 1 FROM dbo.DOI_PROD_IN_MENU WHERE PROD_CATEGORY = 'HQ') " +
                        "INSERT INTO dbo.DOI_PROD_IN_MENU (PROD_CATEGORY, PROCESS_ID, REVISION) VALUES ('HQ', 'COST', '1')"
                    );
                    System.out.println("  HQ (본사)");
                    stmt.execute(
                        "IF NOT EXISTS (SELECT 1 FROM dbo.DOI_PROD_IN_MENU WHERE PROD_CATEGORY = 'VN') " +
                        "INSERT INTO dbo.DOI_PROD_IN_MENU (PROD_CATEGORY, PROCESS_ID, REVISION) VALUES ('VN', 'COST', '1')"
                    );
                    System.out.println("  VN (비나)");
                    stmt.execute(
                        "IF NOT EXISTS (SELECT 1 FROM dbo.DOI_PROD_IN_MENU WHERE PROD_CATEGORY = 'COST') " +
                        "INSERT INTO dbo.DOI_PROD_IN_MENU (PROD_CATEGORY, PROCESS_ID, REVISION) VALUES ('COST', 'COST', '1')"
                    );
                    System.out.println("  COST (원가)");
                    conn.commit();

                    // ============================================
                    // 6. 메뉴 구조 (COST 카테고리) 복사 from 운영DB or 직접 생성
                    // ============================================
                    System.out.println("\n=== Step 6: Creating Menu Structure ===");

                    // Check if menus already exist
                    ResultSet rsChk = stmt.executeQuery("SELECT COUNT(*) AS cnt FROM dbo.DOI_CM_SYS_RESOURCE WHERE PROD_CATEGORY = 'COST'");
                    rsChk.next();
                    int existingMenus = rsChk.getInt("cnt");
                    System.out.println("  Existing COST menus: " + existingMenus);

                    if (existingMenus == 0) {
                        // Root menus
                        String[][] menus = {
                            // {prod_category, sys_resource_id, sys_resource_name, upper_sys_resource_id, type, seq, url}
                            {"COST", "C0001000", "시스템관리", "ROOT_MENU", "D", "1", ""},
                            {"COST", "C0003000", "원가결산", "ROOT_MENU", "D", "2", ""},
                            {"COST", "C0007000", "타시스템 I/F & Upload", "ROOT_MENU", "D", "3", ""},
                            {"COST", "C0008000", "원가레포트", "ROOT_MENU", "D", "4", ""},

                            // 시스템관리 하위
                            {"COST", "C0001009", "사용자-메뉴 권한 관리", "C0001000", "M", "1", "/c0001009"},

                            // 원가결산 하위
                            {"COST", "C0003001", "결산실행", "C0003000", "M", "1", "/c0003001"},
                            {"COST", "C0003002", "원가결산 실행", "C0003000", "M", "2", "/c0003002"},
                            {"COST", "C0003003", "경영계획", "C0003000", "M", "3", "/c0003003"},
                            {"COST", "C0003008", "매출원가", "C0003000", "M", "4", "/c0003008"},
                            {"COST", "C0003009", "제품수불", "C0003000", "M", "5", "/c0003009"},

                            // 타시스템 I/F & Upload 하위
                            {"COST", "C0007001", "기준정보", "C0007000", "M", "1", "/c0007001"},
                            {"COST", "C0007002", "원부자재", "C0007000", "M", "2", "/c0007002"},
                            {"COST", "C0007003", "생산정보", "C0007000", "M", "3", "/c0007003"},
                            {"COST", "C0007004", "수불관리", "C0007000", "M", "4", "/c0007004"},
                            {"COST", "C0007005", "경비관리", "C0007000", "M", "5", "/c0007005"},
                            {"COST", "C0007006", "원가체크", "C0007000", "M", "6", "/c0007006"},
                            {"COST", "C0007007", "재고체크", "C0007000", "M", "7", "/c0007007"},

                            // 원가레포트 하위
                            {"COST", "C0008001", "제조원가", "C0008000", "M", "1", "/c0008001"},
                            {"COST", "C0008002", "원부자재 배부표", "C0008000", "M", "2", "/c0008002"},
                            {"COST", "C0008003", "부서별 경비 집계표", "C0008000", "M", "3", "/c0008003"},
                            {"COST", "C0008004", "판매관리비", "C0008000", "M", "4", "/c0008004"},
                            {"COST", "C0009000", "생산실적", "C0008000", "M", "5", "/c0009000"},
                            {"COST", "C0009001", "생산수불 자체 체크", "C0008000", "M", "6", "/c0009001"},
                            {"COST", "C0009009", "제품별 손익계산서", "C0008000", "M", "7", "/c0009009"},
                        };

                        for (String[] m : menus) {
                            stmt.execute(
                                "INSERT INTO dbo.DOI_CM_SYS_RESOURCE (PROD_CATEGORY, SYS_RESOURCE_ID, SYS_RESOURCE_NAME, UPPER_SYS_RESOURCE_ID, SYS_RESOURCE_TYPE_CODE_ID, SEQ, URL, DEL_YN) " +
                                "VALUES ('" + m[0] + "', '" + m[1] + "', N'" + m[2] + "', '" + m[3] + "', '" + m[4] + "', " + m[5] + ", '" + m[6] + "', 'N')"
                            );
                        }
                        System.out.println("  Created " + menus.length + " COST menu items.");
                    } else {
                        System.out.println("  Menus already exist, skipping creation.");
                    }
                    conn.commit();

                    // ============================================
                    // 7. 역할-메뉴 권한 매핑 (ROLE_ADMIN -> 전체 COST 메뉴)
                    // ============================================
                    System.out.println("\n=== Step 7: Mapping Roles to Menus ===");

                    // Get all COST menus and map to ROLE_ADMIN
                    ResultSet rsMenus = stmt.executeQuery(
                        "SELECT SYS_RESOURCE_ID, UPPER_SYS_RESOURCE_ID, SYS_RESOURCE_TYPE_CODE_ID FROM dbo.DOI_CM_SYS_RESOURCE WHERE PROD_CATEGORY = 'COST' AND DEL_YN = 'N'"
                    );
                    int mappedCount = 0;
                    while (rsMenus.next()) {
                        String sysResId = rsMenus.getString("SYS_RESOURCE_ID");
                        String upperResId = rsMenus.getString("UPPER_SYS_RESOURCE_ID");
                        String typeCode = rsMenus.getString("SYS_RESOURCE_TYPE_CODE_ID");

                        // ROLE_ADMIN
                        try (PreparedStatement ps = conn.prepareStatement(
                            "IF NOT EXISTS (SELECT 1 FROM dbo.doi_cm_role_sys_resource WHERE ROLE_ID=? AND PROD_CATEGORY='COST' AND SYS_RESOURCE_ID=?) " +
                            "INSERT INTO dbo.doi_cm_role_sys_resource (ROLE_ID, PROD_CATEGORY, UPPER_SYS_RESOURCE_ID, SYS_RESOURCE_ID, SYS_RESOURCE_TYPE_CODE_ID) " +
                            "VALUES (?, 'COST', ?, ?, ?)"
                        )) {
                            ps.setString(1, "ROLE_ADMIN");
                            ps.setString(2, sysResId);
                            ps.setString(3, "ROLE_ADMIN");
                            ps.setString(4, upperResId);
                            ps.setString(5, sysResId);
                            ps.setString(6, typeCode);
                            ps.execute();
                        }
                        // ROLE_VN_ADMIN
                        try (PreparedStatement ps = conn.prepareStatement(
                            "IF NOT EXISTS (SELECT 1 FROM dbo.doi_cm_role_sys_resource WHERE ROLE_ID=? AND PROD_CATEGORY='COST' AND SYS_RESOURCE_ID=?) " +
                            "INSERT INTO dbo.doi_cm_role_sys_resource (ROLE_ID, PROD_CATEGORY, UPPER_SYS_RESOURCE_ID, SYS_RESOURCE_ID, SYS_RESOURCE_TYPE_CODE_ID) " +
                            "VALUES (?, 'COST', ?, ?, ?)"
                        )) {
                            ps.setString(1, "ROLE_VN_ADMIN");
                            ps.setString(2, sysResId);
                            ps.setString(3, "ROLE_VN_ADMIN");
                            ps.setString(4, upperResId);
                            ps.setString(5, sysResId);
                            ps.setString(6, typeCode);
                            ps.execute();
                        }
                        mappedCount++;
                    }
                    conn.commit();
                    System.out.println("  Mapped " + mappedCount + " menus to ROLE_ADMIN + ROLE_VN_ADMIN");

                    // ============================================
                    // 8. 결과 확인
                    // ============================================
                    System.out.println("\n=== Final Verification ===");

                    ResultSet rs;
                    rs = stmt.executeQuery("SELECT COUNT(*) AS cnt FROM dbo.doi_cm_user");
                    rs.next(); System.out.println("  Users: " + rs.getInt("cnt"));

                    rs = stmt.executeQuery("SELECT USER_ID, USER_NAME, UTG, ITG, DEL_YN FROM dbo.doi_cm_user");
                    while (rs.next()) {
                        System.out.println("    " + rs.getString("USER_ID") + " / " + rs.getString("USER_NAME") +
                            " (UTG=" + rs.getString("UTG") + ", ITG=" + rs.getString("ITG") + ", DEL=" + rs.getString("DEL_YN") + ")");
                    }

                    rs = stmt.executeQuery("SELECT COUNT(*) AS cnt FROM dbo.DOI_CM_ROLE WHERE DEL_YN='N'");
                    rs.next(); System.out.println("  Roles: " + rs.getInt("cnt"));

                    rs = stmt.executeQuery("SELECT COUNT(*) AS cnt FROM dbo.doi_cm_user_ROLE");
                    rs.next(); System.out.println("  User-Role mappings: " + rs.getInt("cnt"));

                    rs = stmt.executeQuery("SELECT COUNT(*) AS cnt FROM dbo.DOI_CM_SYS_RESOURCE WHERE PROD_CATEGORY='COST' AND DEL_YN='N'");
                    rs.next(); System.out.println("  COST Menus: " + rs.getInt("cnt"));

                    rs = stmt.executeQuery("SELECT COUNT(*) AS cnt FROM dbo.doi_cm_role_sys_resource WHERE PROD_CATEGORY='COST'");
                    rs.next(); System.out.println("  Role-Menu mappings: " + rs.getInt("cnt"));

                    rs = stmt.executeQuery("SELECT COUNT(*) AS cnt FROM dbo.DOI_PROD_IN_MENU");
                    rs.next(); System.out.println("  Site Categories: " + rs.getInt("cnt"));

                    System.out.println("\n========================================");
                    System.out.println("ALL DONE! Accounts & menus seeded successfully.");
                    System.out.println("  Login: SYSADMIN / 1111 (본사+비나)");
                    System.out.println("  Login: VINA / 1111 (비나 전용)");
                    System.out.println("========================================");
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
