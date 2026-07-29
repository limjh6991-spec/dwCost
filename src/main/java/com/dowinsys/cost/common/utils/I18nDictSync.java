package com.dowinsys.cost.common.utils;

import java.io.*;
import java.nio.charset.StandardCharsets;
import java.sql.*;
import java.util.*;
import java.util.regex.*;

/**
 * DOI_I18N_DICT 2차 사전 테이블 생성 및 데이터 적재
 * - DOI_I18N(1차)에서 순수 한국어 단어만 추출
 * - 중복 제거
 * - 전문용어 사전 적용
 */
public class I18nDictSync {

    // 원가/회계 전문용어 의역 사전
    static final Map<String, String> COST_TERMS = new LinkedHashMap<>();
    static {
        // 핵심 원가 용어
        COST_TERMS.put("원가", "Giá thành");
        COST_TERMS.put("원가결산", "Quyết toán giá thành");
        COST_TERMS.put("원가계산", "Tính giá thành");
        COST_TERMS.put("제조원가", "Giá thành sản xuất");
        COST_TERMS.put("매출원가", "Giá vốn hàng bán");
        COST_TERMS.put("재료비", "Chi phí nguyên vật liệu");
        COST_TERMS.put("노무비", "Chi phí nhân công");
        COST_TERMS.put("경비", "Chi phí sản xuất chung");
        COST_TERMS.put("제조경비", "Chi phí sản xuất chung");
        COST_TERMS.put("감가상각비", "Chi phí khấu hao");
        COST_TERMS.put("감가상각", "Khấu hao");
        COST_TERMS.put("결산", "Quyết toán");
        COST_TERMS.put("결산실행", "Thực hiện quyết toán");
        COST_TERMS.put("마감", "Khóa sổ");
        COST_TERMS.put("수불", "Nhập xuất");
        COST_TERMS.put("수불부", "Sổ nhập xuất");
        COST_TERMS.put("입고", "Nhập kho");
        COST_TERMS.put("출고", "Xuất kho");
        COST_TERMS.put("재고", "Tồn kho");
        COST_TERMS.put("기초재고", "Tồn kho đầu kỳ");
        COST_TERMS.put("기말재고", "Tồn kho cuối kỳ");
        COST_TERMS.put("배부", "Phân bổ");
        COST_TERMS.put("배부율", "Tỷ lệ phân bổ");
        COST_TERMS.put("재공품", "Bán thành phẩm");
        COST_TERMS.put("재공", "Bán thành phẩm");
        COST_TERMS.put("완성품", "Thành phẩm");
        COST_TERMS.put("반제품", "Bán thành phẩm");
        COST_TERMS.put("공정", "Công đoạn");
        COST_TERMS.put("계정", "Tài khoản");
        COST_TERMS.put("계정코드", "Mã tài khoản");
        COST_TERMS.put("계정과목", "Tài khoản kế toán");
        COST_TERMS.put("매출", "Doanh thu");
        COST_TERMS.put("매입", "Mua vào");
        COST_TERMS.put("이익", "Lợi nhuận");
        COST_TERMS.put("손익", "Lãi lỗ");
        COST_TERMS.put("자재", "Vật tư");
        COST_TERMS.put("원자재", "Nguyên vật liệu");
        COST_TERMS.put("부자재", "Phụ liệu");
        COST_TERMS.put("원부자재", "Nguyên phụ liệu");
        COST_TERMS.put("품목", "Mặt hàng");
        COST_TERMS.put("품목코드", "Mã mặt hàng");
        COST_TERMS.put("품명", "Tên mặt hàng");
        COST_TERMS.put("규격", "Quy cách");
        COST_TERMS.put("단위", "Đơn vị");
        COST_TERMS.put("단가", "Đơn giá");
        COST_TERMS.put("금액", "Số tiền");
        COST_TERMS.put("수량", "Số lượng");
        COST_TERMS.put("부서", "Phòng ban");
        COST_TERMS.put("부서명", "Tên phòng ban");
        COST_TERMS.put("부서코드", "Mã phòng ban");
        COST_TERMS.put("공장", "Nhà máy");
        COST_TERMS.put("법인", "Pháp nhân");
        COST_TERMS.put("환율", "Tỷ giá hối đoái");
        COST_TERMS.put("환산", "Quy đổi");
        COST_TERMS.put("통화", "Tiền tệ");
        COST_TERMS.put("집계", "Tổng hợp");
        COST_TERMS.put("보고서", "Báo cáo");
        COST_TERMS.put("명세서", "Bảng kê");
        COST_TERMS.put("현황", "Hiện trạng");
        COST_TERMS.put("실적", "Thực tế");
        COST_TERMS.put("예산", "Ngân sách");
        COST_TERMS.put("이월", "Chuyển kỳ");
        COST_TERMS.put("투입", "Đầu vào");
        COST_TERMS.put("산출", "Đầu ra");
        COST_TERMS.put("소요량", "Định mức");
        COST_TERMS.put("소요자재", "Vật tư yêu cầu");
        // UI 공통
        COST_TERMS.put("조회", "Tìm kiếm");
        COST_TERMS.put("저장", "Lưu");
        COST_TERMS.put("삭제", "Xóa");
        COST_TERMS.put("추가", "Thêm");
        COST_TERMS.put("수정", "Sửa");
        COST_TERMS.put("취소", "Hủy");
        COST_TERMS.put("확인", "Xác nhận");
        COST_TERMS.put("닫기", "Đóng");
        COST_TERMS.put("실행", "Thực hiện");
        COST_TERMS.put("적용", "Áp dụng");
        COST_TERMS.put("검색", "Tìm kiếm");
        COST_TERMS.put("선택", "Chọn");
        COST_TERMS.put("전체", "Tất cả");
        COST_TERMS.put("합계", "Tổng cộng");
        COST_TERMS.put("소계", "Tiểu kế");
        COST_TERMS.put("비고", "Ghi chú");
        COST_TERMS.put("등록", "Đăng ký");
        COST_TERMS.put("상세", "Chi tiết");
        COST_TERMS.put("목록", "Danh sách");
        COST_TERMS.put("다운로드", "Tải xuống");
        COST_TERMS.put("업로드", "Tải lên");
        COST_TERMS.put("초기화", "Đặt lại");
        COST_TERMS.put("구분", "Phân loại");
        COST_TERMS.put("코드", "Mã");
        COST_TERMS.put("코드명", "Tên mã");
        COST_TERMS.put("사용", "Sử dụng");
        COST_TERMS.put("미사용", "Không sử dụng");
        COST_TERMS.put("생산", "Sản xuất");
        COST_TERMS.put("제품", "Thành phẩm");
        COST_TERMS.put("기간", "Kỳ");
        COST_TERMS.put("합계", "Tổng cộng");
        COST_TERMS.put("비율", "Tỷ lệ");
        COST_TERMS.put("평균", "Trung bình");
        COST_TERMS.put("변경", "Thay đổi");
        COST_TERMS.put("오류", "Lỗi");
        COST_TERMS.put("입력", "Nhập");
        COST_TERMS.put("관리", "Quản lý");
        COST_TERMS.put("설명", "Mô tả");
        COST_TERMS.put("데이터", "Dữ liệu");
        COST_TERMS.put("판매", "Bán hàng");
        COST_TERMS.put("파일", "Tệp");
        COST_TERMS.put("사이트", "Chi nhánh");
        COST_TERMS.put("언어", "Ngôn ngữ");
        COST_TERMS.put("한국어", "Tiếng Hàn");
        COST_TERMS.put("베트남어", "Tiếng Việt");
        COST_TERMS.put("년", "Năm");
        COST_TERMS.put("월", "Tháng");
        COST_TERMS.put("일", "Ngày");
        COST_TERMS.put("불량", "Lỗi");
    }

    // MES 전용 용어 (제거 대상)
    static final Set<String> MES_TERMS = new HashSet<>(Arrays.asList(
        "세척조온도", "밴딩", "부착압력", "히터온도", "적층", "박리",
        "카세트", "시료", "바코드", "건조", "도포", "에칭",
        "커팅", "라미네이팅", "폴리싱", "검사기", "스크라이빙",
        "모니터링", "센서", "로봇", "컨베이어", "진공"
    ));

    public static void main(String[] args) throws Exception {
        String dbUrl = "jdbc:sqlserver://10.100.40.17:14233;databaseName=DWCMSTEST;encrypt=true;trustServerCertificate=true";
        String user = "cost";
        String pass = "Dowoo1234!";

        Class.forName("com.microsoft.sqlserver.jdbc.SQLServerDriver");
        try (Connection conn = DriverManager.getConnection(dbUrl, user, pass)) {
            System.out.println("Connected!");
            Statement stmt = conn.createStatement();
            conn.setAutoCommit(false);

            try {
                // 1. DOI_I18N_DICT 테이블 생성
                System.out.println("\n=== 1. DOI_I18N_DICT 테이블 생성 ===");
                try {
                    stmt.executeUpdate(
                        "IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'DOI_I18N_DICT') " +
                        "CREATE TABLE DOI_I18N_DICT (" +
                        "  SEQ INT NOT NULL, " +
                        "  KO_WORD NVARCHAR(200) NOT NULL, " +
                        "  VI_WORD NVARCHAR(500) NOT NULL DEFAULT '', " +
                        "  FREQUENCY INT DEFAULT 1, " +
                        "  CATEGORY NVARCHAR(50) DEFAULT 'COMMON', " +
                        "  USE_YN CHAR(1) DEFAULT 'Y', " +
                        "  REG_DATE DATETIME DEFAULT GETDATE(), " +
                        "  UPD_DATE DATETIME NULL, " +
                        "  CONSTRAINT PK_DOI_I18N_DICT PRIMARY KEY (SEQ)" +
                        ")"
                    );
                    // Unique index
                    try {
                        stmt.executeUpdate(
                            "IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'UX_DOI_I18N_DICT_KO') " +
                            "CREATE UNIQUE INDEX UX_DOI_I18N_DICT_KO ON DOI_I18N_DICT(KO_WORD)"
                        );
                    } catch (Exception e) { /* index may exist */ }
                    System.out.println("  테이블 생성/확인 완료");
                } catch (Exception e) {
                    System.out.println("  테이블 이미 존재: " + e.getMessage());
                }

                // 2. DOI_I18N에서 한국어 단어 추출
                System.out.println("\n=== 2. DOI_I18N에서 한국어 단어 추출 ===");
                ResultSet rs = stmt.executeQuery("SELECT KO_TEXT, VI_TEXT FROM DOI_I18N WHERE USE_YN = 'Y'");

                // 단어 사전: word -> {frequency, viText}
                Map<String, int[]> wordFreq = new LinkedHashMap<>();
                Map<String, String> wordVi = new LinkedHashMap<>();
                Pattern koreanPattern = Pattern.compile("[\\uAC00-\\uD7AF]{2,}");

                int rawCount = 0;
                while (rs.next()) {
                    rawCount++;
                    String koText = rs.getNString("KO_TEXT");
                    String viText = rs.getNString("VI_TEXT");
                    if (koText == null) continue;

                    // 한국어 단어 추출
                    Matcher m = koreanPattern.matcher(koText);
                    while (m.find()) {
                        String word = m.group();
                        
                        // MES 용어 필터
                        boolean isMes = false;
                        for (String mes : MES_TERMS) {
                            if (word.contains(mes)) { isMes = true; break; }
                        }
                        if (isMes) continue;

                        wordFreq.merge(word, new int[]{1}, (a, b) -> { a[0]++; return a; });
                        
                        // 기존 번역이 있고 아직 매핑 안 된 경우
                        if (!wordVi.containsKey(word) && viText != null && !viText.isEmpty()) {
                            // 원문과 정확히 일치하면 번역 매핑
                            if (koText.trim().equals(word)) {
                                wordVi.put(word, viText);
                            }
                        }
                    }
                }
                System.out.println("  1차 데이터: " + rawCount + "건");
                System.out.println("  추출 단어: " + wordFreq.size() + "개");

                // 3. 전문용어 사전 적용
                System.out.println("\n=== 3. 전문용어 사전 적용 ===");
                int overridden = 0;
                for (Map.Entry<String, String> term : COST_TERMS.entrySet()) {
                    String ko = term.getKey();
                    String vi = term.getValue();
                    wordVi.put(ko, vi);
                    if (!wordFreq.containsKey(ko)) {
                        wordFreq.put(ko, new int[]{0}); // 빈도 0이지만 필수 용어
                    }
                    overridden++;
                }
                System.out.println("  전문용어 적용: " + overridden + "개");

                int withVi = 0;
                for (String word : wordFreq.keySet()) {
                    if (wordVi.containsKey(word) && !wordVi.get(word).isEmpty()) withVi++;
                }
                System.out.println("  번역 있음: " + withVi + "개");
                System.out.println("  미번역: " + (wordFreq.size() - withVi) + "개");

                // 4. DOI_I18N_DICT INSERT
                System.out.println("\n=== 4. DOI_I18N_DICT INSERT ===");
                stmt.executeUpdate("DELETE FROM DOI_I18N_DICT");

                PreparedStatement ps = conn.prepareStatement(
                    "INSERT INTO DOI_I18N_DICT (SEQ, KO_WORD, VI_WORD, FREQUENCY, CATEGORY, USE_YN, REG_DATE) " +
                    "VALUES (?, ?, ?, ?, 'COMMON', 'Y', GETDATE())"
                );

                // 빈도 높은 순 정렬
                List<Map.Entry<String, int[]>> sortedEntries = new ArrayList<>(wordFreq.entrySet());
                sortedEntries.sort((a, b) -> b.getValue()[0] - a.getValue()[0]);

                int seq = 1;
                int inserted = 0;
                for (Map.Entry<String, int[]> entry : sortedEntries) {
                    String word = entry.getKey();
                    int freq = entry.getValue()[0];
                    String vi = wordVi.getOrDefault(word, "");

                    ps.setInt(1, seq++);
                    ps.setNString(2, word);
                    ps.setNString(3, vi);
                    ps.setInt(4, freq);
                    ps.addBatch();
                    inserted++;

                    if (inserted % 500 == 0) {
                        ps.executeBatch();
                        System.out.println("  INSERT: " + inserted + "건...");
                    }
                }
                ps.executeBatch();
                System.out.println("  INSERT 완료: " + inserted + "건");

                // 5. 검증
                System.out.println("\n=== 5. 검증 ===");
                rs = stmt.executeQuery("SELECT COUNT(*) FROM DOI_I18N_DICT");
                rs.next();
                System.out.println("  전체: " + rs.getInt(1) + "건");

                rs = stmt.executeQuery("SELECT COUNT(*) FROM DOI_I18N_DICT WHERE VI_WORD != ''");
                rs.next();
                System.out.println("  번역됨: " + rs.getInt(1) + "건");

                rs = stmt.executeQuery("SELECT TOP 20 KO_WORD, VI_WORD, FREQUENCY FROM DOI_I18N_DICT ORDER BY FREQUENCY DESC");
                System.out.println("\n  Top 20:");
                while (rs.next()) {
                    System.out.println("    [" + rs.getInt("FREQUENCY") + "회] " + 
                        rs.getNString("KO_WORD") + " -> " + rs.getNString("VI_WORD"));
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
