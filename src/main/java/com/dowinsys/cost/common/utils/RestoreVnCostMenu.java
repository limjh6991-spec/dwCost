package com.dowinsys.cost.common.utils;

import java.sql.*;

/**
 * VN 제조원가 집계(C0003001)에 경비집계/가공비배부/재공평가 탭 복원.
 *
 * 배경: FixVnCostMenu 가 VN의 본사 탭 TAB030001~005 를 전부 제거했는데,
 *       재료비집계/배부(TAB030003/004)는 신규 VN 재료비 4탭(TAB030009~012)으로 대체되어 제외가 맞지만
 *       경비집계(TAB030001)/가공비배부(TAB030002)/재공평가(TAB030005)는 VN 결산에도 필요하여 다시 추가한다.
 *
 * 결과 탭 순서: 경비집계(1) → 가공비배부(2) → ①재고조정(6) → ②재료비원장(7)
 *              → ③재료비집계(8) → ④재료비배부(9) → 재공평가(10)
 *
 * 실행: main() 수동 실행 (앱 부팅과 무관). 운영 반영 시 databaseName 만 도우제조원가시스템으로 바꿔 실행.
 */
public class RestoreVnCostMenu {
    public static void main(String[] args) throws Exception {
        String dbUrl = "jdbc:sqlserver://10.100.40.17:14233;databaseName=DWCMSTEST;encrypt=true;trustServerCertificate=true";
        Class.forName("com.microsoft.sqlserver.jdbc.SQLServerDriver");

        // {SYS_RESOURCE_ID, 이름, SEQ, URL}
        String[][] tabs = {
            {"TAB030001", "경비 집계",   "1",  "/c0003001?tab3Id=TAB030001"},
            {"TAB030002", "가공비 배부", "2",  "/c0003001?tab3Id=TAB030002"},
            {"TAB030005", "재공 평가",   "10", "/c0003001?tab3Id=TAB030005"},
        };
        String[] roles = {"SYSADMIN", "BIZADMIN"};

        try (Connection conn = DriverManager.getConnection(dbUrl, "cost", "Dowoo1234!")) {
            conn.setAutoCommit(false);
            Statement stmt = conn.createStatement();
            try {
                System.out.println("=== VN 제조원가 집계 탭 복원 ===");
                for (String[] t : tabs) {
                    String tid = t[0], name = t[1]; int seq = Integer.parseInt(t[2]); String url = t[3];

                    ResultSet rs = stmt.executeQuery(
                        "SELECT COUNT(*) FROM DOI_CM_SYS_RESOURCE WHERE PROD_CATEGORY='VN' AND SYS_RESOURCE_ID='" + tid + "'");
                    rs.next();
                    if (rs.getInt(1) == 0) {
                        try (PreparedStatement ps = conn.prepareStatement(
                            "INSERT INTO DOI_CM_SYS_RESOURCE (prod_category, SYS_RESOURCE_ID, SYS_RESOURCE_NAME, UPPER_SYS_RESOURCE_ID, " +
                            "SYS_RESOURCE_TYPE_CODE_ID, DESCRIPTION, SEQ, URL, INIT_DT, INIT_USER, DEL_YN) " +
                            "VALUES ('VN', ?, ?, 'C0003001', 'TAB', ?, ?, ?, GETDATE(), 'SYSADMIN', 'N')")) {
                            ps.setString(1, tid); ps.setNString(2, name); ps.setNString(3, name);
                            ps.setInt(4, seq); ps.setString(5, url); ps.executeUpdate();
                        }
                        System.out.println("  메뉴 INSERT: VN " + tid + " (" + name + ") SEQ=" + seq);
                    } else {
                        try (PreparedStatement ps = conn.prepareStatement(
                            "UPDATE DOI_CM_SYS_RESOURCE SET DEL_YN='N', SYS_RESOURCE_NAME=?, SEQ=?, URL=? " +
                            "WHERE PROD_CATEGORY='VN' AND SYS_RESOURCE_ID=?")) {
                            ps.setNString(1, name); ps.setInt(2, seq); ps.setString(3, url); ps.setString(4, tid);
                            ps.executeUpdate();
                        }
                        System.out.println("  메뉴 UPDATE(복구): VN " + tid);
                    }

                    for (String role : roles) {
                        rs = stmt.executeQuery(
                            "SELECT COUNT(*) FROM DOI_CM_ROLE_SYS_RESOURCE WHERE ROLE_ID='" + role + "' AND PROD_CATEGORY='VN' AND SYS_RESOURCE_ID='" + tid + "'");
                        rs.next();
                        if (rs.getInt(1) == 0) {
                            stmt.executeUpdate(
                                "INSERT INTO DOI_CM_ROLE_SYS_RESOURCE (ROLE_ID, prod_category, UPPER_SYS_RESOURCE_ID, SYS_RESOURCE_ID, SYS_RESOURCE_TYPE_CODE_ID, INIT_DT, INIT_USER) " +
                                "VALUES ('" + role + "', 'VN', 'C0003001', '" + tid + "', 'TAB', GETDATE(), 'SYSADMIN')");
                            System.out.println("    역할 매핑: " + role + " -> VN " + tid);
                        }
                    }
                }

                System.out.println("\n=== 복원 후 VN C0003001 하위 탭 (SEQ순) ===");
                ResultSet rs = stmt.executeQuery(
                    "SELECT SYS_RESOURCE_ID, SYS_RESOURCE_NAME, SEQ FROM DOI_CM_SYS_RESOURCE " +
                    "WHERE PROD_CATEGORY='VN' AND UPPER_SYS_RESOURCE_ID='C0003001' AND SYS_RESOURCE_TYPE_CODE_ID='TAB' " +
                    "AND ISNULL(DEL_YN,'N')<>'Y' ORDER BY SEQ");
                while (rs.next()) {
                    System.out.println("  SEQ=" + rs.getInt("SEQ") + "  " + rs.getString("SYS_RESOURCE_ID") + "  " + rs.getNString("SYS_RESOURCE_NAME"));
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
