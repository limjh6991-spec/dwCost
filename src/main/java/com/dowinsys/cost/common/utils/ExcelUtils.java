package com.dowinsys.cost.common.utils;

import org.apache.poi.hssf.usermodel.HSSFWorkbook;
import org.apache.poi.ss.usermodel.*;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.springframework.web.multipart.MultipartFile;

import java.io.InputStream;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class ExcelUtils {

	/**
     * 엑셀 파일을 읽어 필터된 데이터를 반환. 헤더가 없으며, 필터링할 headers 순서대로 데이터 매핑.
     *
     * @param inputStream 엑셀 파일의 InputStream
     * @param fileName    업로드된 파일 이름
     * @param headers     필터링할 헤더 목록
     * @return List<Map<String, String>> 형태의 데이터
     * @throws Exception 파일 읽기 중 예외
     */
    public static List<Map<String, String>> readExcel(MultipartFile file, List<String> headers, int startRow) throws Exception {
        List<Map<String, String>> dataList = new ArrayList<>();

        try (Workbook workbook = getWorkbook(file.getInputStream(), file.getOriginalFilename())) {
            Sheet sheet = workbook.getSheetAt(0);
            int actualStartRow = (startRow >= 0) ? startRow : 0;
            
            for (int i = actualStartRow; i <= sheet.getLastRowNum(); i++) {
                Row row = sheet.getRow(i);
                if (row == null) continue;

                Map<String, String> rowData = new HashMap<>();
                for (int j = 0; j < headers.size(); j++) {
                    Cell cell = row.getCell(j);
                    rowData.put(headers.get(j), getCellValueAsString(cell));
                }
                dataList.add(rowData);
            }
        }
        return dataList;
    }

    /**
     * 엑셀 파일을 읽어 필터된 데이터를 반환. 헤더가 없으며, 필터링할 headers 순서대로 데이터 매핑.
     *
     * @param inputStream 엑셀 파일의 InputStream
     * @param fileName    업로드된 파일 이름
     * @param headers     필터링할 헤더 목록
     * @return List<Map<String, String>> 형태의 데이터
     * @throws Exception 파일 읽기 중 예외
     */
    public static List<Map<String, String>> readExcel(MultipartFile file, List<String> headers, int startRow, boolean isStringOnly, boolean isNotNull) throws Exception {
        List<Map<String, String>> dataList = new ArrayList<>();

        try (Workbook workbook = getWorkbook(file.getInputStream(), file.getOriginalFilename())) {
            Sheet sheet = workbook.getSheetAt(0);
            int actualStartRow = (startRow >= 0) ? startRow : 0;

            for (int i = actualStartRow; i <= sheet.getLastRowNum(); i++) {
                Row row = sheet.getRow(i);
                if (row == null) continue;

                Map<String, String> rowData = new HashMap<>();
                for (int j = 0; j < headers.size(); j++) {
                    Cell cell = row.getCell(j);
                    if(cell != null && isStringOnly) {
                        cell.setCellType(CellType.STRING);
                    }
                    rowData.put(headers.get(j), getCellValueAsString(cell));
                }
                if(isNotNull && rowData.get(headers.get(0)) != null && !("".equalsIgnoreCase(rowData.get(headers.get(0)))))
                    dataList.add(rowData);
            }
        }
        return dataList;
    }

    /**
     * 확장자에 따라 Workbook 객체 생성.
     *
     * @param inputStream 엑셀 파일의 InputStream
     * @param fileName    업로드된 파일 이름
     * @return Workbook 객체
     * @throws Exception 지원되지 않는 파일 확장자일 경우
     */
    private static Workbook getWorkbook(InputStream inputStream, String fileName) throws Exception {
        if (fileName.endsWith(".xlsx")) {
            return new XSSFWorkbook(inputStream);
        } else if (fileName.endsWith(".xls")) {
            return new HSSFWorkbook(inputStream);
        } else {
            throw new Exception("지원하지 않는 파일 형식: " + fileName);
        }
    }

    /**
     * 셀의 값을 읽어서 String 형태로 반환.
     *
     * @param cell 셀
     * @return String 형태의 값
     */
    private static String getCellValueAsString(Cell cell) {
        if (cell == null) return "";

        switch (cell.getCellType()) {
            case STRING:
                return cell.getStringCellValue();
            case NUMERIC:
                if (DateUtil.isCellDateFormatted(cell)) {
                    return cell.getDateCellValue().toString();
                } else {
                    return String.valueOf(cell.getNumericCellValue());
                }
            case BOOLEAN:
                return String.valueOf(cell.getBooleanCellValue());
            case FORMULA:
                return cell.getCellFormula();
            default:
                return "";
        }
    }
}
