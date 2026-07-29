package com.dowinsys.cost.common.utils;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;

import java.io.File;
import java.sql.*;
import java.util.Map;

/**
 * DOI_I18N 테이블 다국어 데이터 업로더
 * 대상: 10.100.40.17:14233 / DWCMSTEST / dbo
 * 테이블 구조: SEQ(INT NOT NULL), KO_TEXT, VI_TEXT, CATEGORY, USE_YN, REG_DATE
 */
public class I18nUploader {

    public static void main(String[] args) {
        String dbUrl = "jdbc:sqlserver://10.100.40.17:14233;databaseName=DWCMSTEST;encrypt=true;trustServerCertificate=true";
        String user = "cost";
        String pass = "Dowoo1234!";

        File jsonFile = new File("src/main/vue/src/assets/i18n/ko_to_vi.json");
        if (!jsonFile.exists()) {
            System.err.println("JSON file not found: " + jsonFile.getAbsolutePath());
            return;
        }

        try {
            ObjectMapper mapper = new ObjectMapper();
            Map<String, String> translations = mapper.readValue(jsonFile, new TypeReference<Map<String, String>>() {});
            System.out.println("Loaded " + translations.size() + " translation entries from ko_to_vi.json");

            Class.forName("com.microsoft.sqlserver.jdbc.SQLServerDriver");
            System.out.println("Connecting to " + dbUrl + " ...");

            try (Connection conn = DriverManager.getConnection(dbUrl, user, pass)) {
                System.out.println("Connected to DWCMSTEST successfully!");

                // Check table structure
                try (Statement stmt = conn.createStatement()) {
                    ResultSet rs = stmt.executeQuery(
                        "SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE, COLUMNPROPERTY(OBJECT_ID('dbo.DOI_I18N'), COLUMN_NAME, 'IsIdentity') AS IS_IDENTITY " +
                        "FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'DOI_I18N' ORDER BY ORDINAL_POSITION");
                    System.out.println("--- DOI_I18N Table Structure ---");
                    while (rs.next()) {
                        System.out.println("  " + rs.getString("COLUMN_NAME") +
                            " (" + rs.getString("DATA_TYPE") + ")" +
                            " nullable=" + rs.getString("IS_NULLABLE") +
                            " identity=" + rs.getInt("IS_IDENTITY"));
                    }
                }

                // Check existing MAX(SEQ)
                int maxSeq = 0;
                try (Statement stmt = conn.createStatement()) {
                    ResultSet rs = stmt.executeQuery("SELECT ISNULL(MAX(SEQ), 0) AS maxSeq FROM dbo.DOI_I18N");
                    if (rs.next()) {
                        maxSeq = rs.getInt("maxSeq");
                    }
                    System.out.println("Existing MAX(SEQ) = " + maxSeq);
                }

                // Check existing row count
                try (Statement stmt = conn.createStatement()) {
                    ResultSet rs = stmt.executeQuery("SELECT COUNT(*) AS cnt FROM dbo.DOI_I18N");
                    if (rs.next()) {
                        System.out.println("Existing rows in DOI_I18N: " + rs.getInt("cnt"));
                    }
                }

                // UPSERT with SEQ
                String upsertSql =
                    "IF EXISTS (SELECT 1 FROM dbo.DOI_I18N WHERE KO_TEXT = ?) " +
                    "    UPDATE dbo.DOI_I18N SET VI_TEXT = ? WHERE KO_TEXT = ?; " +
                    "ELSE " +
                    "    INSERT INTO dbo.DOI_I18N (SEQ, KO_TEXT, VI_TEXT, CATEGORY, USE_YN, REG_DATE) " +
                    "    VALUES (?, ?, ?, 'COMMON', 'Y', GETDATE());";

                conn.setAutoCommit(false);
                int count = 0;
                int seq = maxSeq;

                try (PreparedStatement pstmt = conn.prepareStatement(upsertSql)) {
                    for (Map.Entry<String, String> entry : translations.entrySet()) {
                        String ko = entry.getKey();
                        String vi = entry.getValue();
                        seq++;

                        // UPDATE part params
                        pstmt.setNString(1, ko);   // WHERE KO_TEXT = ?
                        pstmt.setNString(2, vi);   // SET VI_TEXT = ?
                        pstmt.setNString(3, ko);   // WHERE KO_TEXT = ?

                        // INSERT part params
                        pstmt.setInt(4, seq);      // SEQ
                        pstmt.setNString(5, ko);   // KO_TEXT
                        pstmt.setNString(6, vi);   // VI_TEXT

                        pstmt.addBatch();
                        count++;

                        if (count % 500 == 0) {
                            pstmt.executeBatch();
                            conn.commit();
                            System.out.println("Processed " + count + " / " + translations.size() + " entries...");
                        }
                    }
                    pstmt.executeBatch();
                    conn.commit();
                }

                // Verify final count
                try (Statement stmt = conn.createStatement()) {
                    ResultSet rs = stmt.executeQuery("SELECT COUNT(*) AS cnt FROM dbo.DOI_I18N");
                    if (rs.next()) {
                        System.out.println("Final rows in DOI_I18N: " + rs.getInt("cnt"));
                    }
                }

                System.out.println("SUCCESS! Processed total " + count + " entries to DWCMSTEST.dbo.DOI_I18N");
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
