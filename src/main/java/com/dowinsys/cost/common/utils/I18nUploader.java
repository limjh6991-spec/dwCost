package com.dowinsys.cost.common.utils;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;

import java.io.File;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.Statement;
import java.util.Map;

public class I18nUploader {

    public static void main(String[] args) {
        String dbUrl = "jdbc:sqlserver://172.16.0.208:1433;databaseName=DWCMSTEST;encrypt=true;trustServerCertificate=true";
        String user = "bs";
        String pass = "ehdndlstltm1!";

        File jsonFile = new File("src/main/vue/src/assets/i18n/ko_to_vi.json");
        if (!jsonFile.exists()) {
            System.err.println("JSON file not found: " + jsonFile.getAbsolutePath());
            return;
        }

        try {
            ObjectMapper mapper = new ObjectMapper();
            Map<String, String> translations = mapper.readValue(jsonFile, new TypeReference<Map<String, String>>() {});
            System.out.println("Loaded " + translations.size() + " translation entries.");

            Class.forName("com.microsoft.sqlserver.jdbc.SQLServerDriver");
            System.out.println("Connecting to " + dbUrl + " ...");
            try (Connection conn = DriverManager.getConnection(dbUrl, user, pass)) {
                System.out.println("Connected successfully!");

                // Ensure table exists
                String createTableSql = "IF OBJECT_ID('dbo.DOI_I18N', 'U') IS NULL " +
                        "CREATE TABLE dbo.DOI_I18N (" +
                        "    LANG_KEY NVARCHAR(500) NOT NULL PRIMARY KEY, " +
                        "    KO_TEXT  NVARCHAR(MAX) NULL, " +
                        "    VI_TEXT  NVARCHAR(MAX) NULL, " +
                        "    USE_YN   VARCHAR(1) DEFAULT 'Y', " +
                        "    INIT_DT  DATETIME DEFAULT GETDATE() " +
                        ")";
                try (Statement stmt = conn.createStatement()) {
                    stmt.execute(createTableSql);
                    System.out.println("Verified/Created dbo.DOI_I18N table.");
                }

                String upsertSql = "IF EXISTS (SELECT 1 FROM dbo.DOI_I18N WHERE LANG_KEY = ?) " +
                        "    UPDATE dbo.DOI_I18N SET VI_TEXT = ?, KO_TEXT = ? WHERE LANG_KEY = ?; " +
                        "ELSE " +
                        "    INSERT INTO dbo.DOI_I18N (LANG_KEY, KO_TEXT, VI_TEXT, USE_YN, INIT_DT) VALUES (?, ?, ?, 'Y', GETDATE());";

                conn.setAutoCommit(false);
                int count = 0;
                try (PreparedStatement pstmt = conn.prepareStatement(upsertSql)) {
                    for (Map.Entry<String, String> entry : translations.entrySet()) {
                        String ko = entry.getKey();
                        String vi = entry.getValue();

                        pstmt.setString(1, ko);
                        pstmt.setString(2, vi);
                        pstmt.setString(3, ko);
                        pstmt.setString(4, ko);

                        pstmt.setString(5, ko);
                        pstmt.setString(6, ko);
                        pstmt.setString(7, vi);

                        pstmt.addBatch();
                        count++;

                        if (count % 200 == 0) {
                            pstmt.executeBatch();
                            conn.commit();
                            System.out.println("Uploaded " + count + " / " + translations.size() + " entries...");
                        }
                    }
                    pstmt.executeBatch();
                    conn.commit();
                }

                System.out.println("SUCCESS! Uploaded total " + count + " entries to DWCMSTEST.dbo.DOI_I18N.");
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
