package com.dowinsys.cost.common.utils;

import java.sql.*;

public class VnMenuRegister {
    public static void main(String[] args) throws Exception {
        String dbUrl = "jdbc:sqlserver://10.100.40.17:14233;databaseName=DWCMSTEST;encrypt=true;trustServerCertificate=true";
        Class.forName("com.microsoft.sqlserver.jdbc.SQLServerDriver");
        try (Connection conn = DriverManager.getConnection(dbUrl, "cost", "Dowoo1234!")) {
            conn.setAutoCommit(false);
            Statement stmt = conn.createStatement();
            try {
                // 1. 기존 C0007012~015 메뉴 삭제 (VN)
                System.out.println("=== 기존 C0007012~015 VN 메뉴 삭제 ===");
                String[] oldMenus = {"C0007012", "C0007013", "C0007014", "C0007015"};
                for (String menuId : oldMenus) {
                    stmt.executeUpdate("DELETE FROM DOI_CM_ROLE_SYS_RESOURCE WHERE PROD_CATEGORY='VN' AND SYS_RESOURCE_ID='" + menuId + "'");
                    int del = stmt.executeUpdate("DELETE FROM DOI_CM_SYS_RESOURCE WHERE PROD_CATEGORY='VN' AND SYS_RESOURCE_ID='" + menuId + "'");
                    System.out.println("  " + menuId + " 삭제: " + del);
                }

                // 2. C0007002 VN 다시 숨김 유지 (이미 숨김 상태)
                stmt.executeUpdate("UPDATE DOI_CM_SYS_RESOURCE SET DEL_YN='Y' WHERE PROD_CATEGORY='VN' AND SYS_RESOURCE_ID='C0007002'");
                System.out.println("\nC0007002 VN 숨김 유지");

                // 3. C0007016 메뉴 등록 (VN 전용)
                System.out.println("\n=== C0007016 등록 ===");
                ResultSet rs = stmt.executeQuery("SELECT COUNT(*) FROM DOI_CM_SYS_RESOURCE WHERE PROD_CATEGORY='VN' AND SYS_RESOURCE_ID='C0007016'");
                rs.next();
                if (rs.getInt(1) == 0) {
                    stmt.executeUpdate(
                        "INSERT INTO DOI_CM_SYS_RESOURCE (prod_category, SYS_RESOURCE_ID, UPPER_SYS_RESOURCE_ID, SYS_RESOURCE_NAME, " +
                        "DESCRIPTION, SYS_RESOURCE_TYPE_CODE_ID, DEL_YN, SEQ, URL, INIT_DT, INIT_USER) " +
                        "VALUES ('VN', 'C0007016', 'C0007000', N'자재투입정보', N'자재투입정보(VN)', 'M', 'N', 2, '/c0007016', GETDATE(), 'SYSADMIN')"
                    );
                    System.out.println("  C0007016 메뉴 등록 완료");
                } else {
                    stmt.executeUpdate("UPDATE DOI_CM_SYS_RESOURCE SET DEL_YN='N', SYS_RESOURCE_NAME=N'자재투입정보' WHERE PROD_CATEGORY='VN' AND SYS_RESOURCE_ID='C0007016'");
                    System.out.println("  C0007016 메뉴 갱신 완료");
                }

                // 역할 매핑
                String[] roles = {"SYSADMIN", "BIZADMIN"};
                for (String role : roles) {
                    rs = stmt.executeQuery("SELECT COUNT(*) FROM DOI_CM_ROLE_SYS_RESOURCE WHERE ROLE_ID='" + role + "' AND PROD_CATEGORY='VN' AND SYS_RESOURCE_ID='C0007016'");
                    rs.next();
                    if (rs.getInt(1) == 0) {
                        stmt.executeUpdate(
                            "INSERT INTO DOI_CM_ROLE_SYS_RESOURCE (ROLE_ID, prod_category, UPPER_SYS_RESOURCE_ID, SYS_RESOURCE_ID, SYS_RESOURCE_TYPE_CODE_ID, INIT_DT, INIT_USER) " +
                            "VALUES ('" + role + "', 'VN', 'C0007000', 'C0007016', 'M', GETDATE(), 'SYSADMIN')"
                        );
                        System.out.println("  역할 매핑: " + role + " -> C0007016");
                    }
                }

                // 4. 탭 4개 등록 (TAB070020~023)
                System.out.println("\n=== TAB 등록 ===");
                String[][] tabs = {
                    {"TAB070020", "품목별투입조회", "1"},
                    {"TAB070021", "기타입출고금액조회(통합)", "2"},
                    {"TAB070022", "재고금액상세조회(통합)", "3"},
                    {"TAB070023", "자재조회", "4"},
                };

                for (String[] tab : tabs) {
                    rs = stmt.executeQuery("SELECT COUNT(*) FROM DOI_CM_SYS_RESOURCE WHERE PROD_CATEGORY='VN' AND SYS_RESOURCE_ID='" + tab[0] + "'");
                    rs.next();
                    if (rs.getInt(1) == 0) {
                        stmt.executeUpdate(
                            "INSERT INTO DOI_CM_SYS_RESOURCE (prod_category, SYS_RESOURCE_ID, UPPER_SYS_RESOURCE_ID, SYS_RESOURCE_NAME, " +
                            "DESCRIPTION, SYS_RESOURCE_TYPE_CODE_ID, DEL_YN, SEQ, INIT_DT, INIT_USER) " +
                            "VALUES ('VN', '" + tab[0] + "', 'C0007016', N'" + tab[1] + "', N'" + tab[1] + "', 'TAB', 'N', " + tab[2] + ", GETDATE(), 'SYSADMIN')"
                        );
                        System.out.println("  탭 등록: " + tab[0] + " (" + tab[1] + ")");
                    } else {
                        System.out.println("  탭 이미 존재: " + tab[0]);
                    }

                    // 역할 매핑
                    for (String role : roles) {
                        rs = stmt.executeQuery("SELECT COUNT(*) FROM DOI_CM_ROLE_SYS_RESOURCE WHERE ROLE_ID='" + role + "' AND PROD_CATEGORY='VN' AND SYS_RESOURCE_ID='" + tab[0] + "'");
                        rs.next();
                        if (rs.getInt(1) == 0) {
                            stmt.executeUpdate(
                                "INSERT INTO DOI_CM_ROLE_SYS_RESOURCE (ROLE_ID, prod_category, UPPER_SYS_RESOURCE_ID, SYS_RESOURCE_ID, SYS_RESOURCE_TYPE_CODE_ID, INIT_DT, INIT_USER) " +
                                "VALUES ('" + role + "', 'VN', 'C0007016', '" + tab[0] + "', 'TAB', GETDATE(), 'SYSADMIN')"
                            );
                        }
                    }
                }

                // 5. 최종 확인
                System.out.println("\n=== 최종 VN C0007000 하위 메뉴 ===");
                rs = stmt.executeQuery(
                    "SELECT SYS_RESOURCE_ID, SYS_RESOURCE_NAME, DEL_YN, URL, SEQ " +
                    "FROM DOI_CM_SYS_RESOURCE WHERE PROD_CATEGORY='VN' AND UPPER_SYS_RESOURCE_ID='C0007000' " +
                    "ORDER BY SEQ"
                );
                while (rs.next()) {
                    System.out.println("  " + rs.getString("SYS_RESOURCE_ID") + " - " +
                        rs.getNString("SYS_RESOURCE_NAME") + " [DEL=" + rs.getString("DEL_YN") +
                        "] " + rs.getString("URL"));
                }

                System.out.println("\n=== C0007016 하위 탭 ===");
                rs = stmt.executeQuery(
                    "SELECT SYS_RESOURCE_ID, SYS_RESOURCE_NAME, SEQ " +
                    "FROM DOI_CM_SYS_RESOURCE WHERE PROD_CATEGORY='VN' AND UPPER_SYS_RESOURCE_ID='C0007016' ORDER BY SEQ"
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
