<template>
  <div></div>
</template>
<script>
import ExcelJS from '@plugins/exceljs.js';
import HqExcelTmp from '@/assets/excel/DOI_ReportTemplate1.xlsx';
import VnExcelTmp from '@/assets/excel/DOI_ReportTemplate2.xlsx';

export default {
  data() {
    return {
      workbook: null,
    };
  },
  methods: {
    async loadExcel(site) {
      try {
        let filePath = site === 'HQ' ? HqExcelTmp : VnExcelTmp;
        //TODO: VN 템플릿 새로 작성 필요 (현재는 본사 템플릿 복사본 사용 중)
        const response = await fetch(filePath);
        const arrayBuffer = await response.arrayBuffer();

        // ExcelJS로 엑셀 파일 로드
        const workbook = new ExcelJS.Workbook();
        await workbook.xlsx.load(arrayBuffer);
        this.workbook = workbook;
      } catch (error) {
        console.error('엑셀 파일 로드 오류:', error);
      }
    },
    async addDataToExcel(yyyy, data) {
      if (!this.workbook) {
        await this.loadExcel();
      }

      try {
        const worksheet = this.workbook.getWorksheet('Sheet1');
        worksheet.getCell('C4').value = yyyy.substring(2,4) + '年\n실행'
        worksheet.getCell('C4').alignment = { vertical: 'middle', horizontal: 'center', wrapText: true }

        data.forEach((item, index) => {
          var rowNumber = index + 6;
          worksheet.getCell('B' + rowNumber).value = item['구분'];
          worksheet.getCell('C' + rowNumber).value = item['tot'];
          worksheet.getCell('D' + rowNumber).value = item['1월'];
          worksheet.getCell('E' + rowNumber).value = item['2월'];
          worksheet.getCell('F' + rowNumber).value = item['3월'];
          worksheet.getCell('G' + rowNumber).value = item['4월'];
          worksheet.getCell('H' + rowNumber).value = item['5월'];
          worksheet.getCell('I' + rowNumber).value = item['6월'];
          worksheet.getCell('J' + rowNumber).value = item['7월'];
          worksheet.getCell('K' + rowNumber).value = item['8월'];
          worksheet.getCell('L' + rowNumber).value = item['9월'];
          worksheet.getCell('M' + rowNumber).value = item['10월'];
          worksheet.getCell('N' + rowNumber).value = item['11월'];
          worksheet.getCell('O' + rowNumber).value = item['12월'];

          worksheet.getCell('C' + rowNumber).numFmt = '#,##0';
          worksheet.getCell('D' + rowNumber).numFmt = '#,##0';
          worksheet.getCell('E' + rowNumber).numFmt = '#,##0';
          worksheet.getCell('F' + rowNumber).numFmt = '#,##0';
          worksheet.getCell('G' + rowNumber).numFmt = '#,##0';
          worksheet.getCell('H' + rowNumber).numFmt = '#,##0';
          worksheet.getCell('I' + rowNumber).numFmt = '#,##0';
          worksheet.getCell('J' + rowNumber).numFmt = '#,##0';
          worksheet.getCell('K' + rowNumber).numFmt = '#,##0';
          worksheet.getCell('L' + rowNumber).numFmt = '#,##0';
          worksheet.getCell('M' + rowNumber).numFmt = '#,##0';
          worksheet.getCell('N' + rowNumber).numFmt = '#,##0';
          worksheet.getCell('O' + rowNumber).numFmt = '#,##0';
        });
      } catch (error) {
        console.error('엑셀 데이터 추가 오류:', error);
      }
    },
    async downloadExcel() {
      if (!this.workbook) {
        await this.loadExcel();
      }

      try {
        const now = new Date();
        const yyyymmdd = this.$utils.getTodayDate();

        const hours = String(now.getHours()).padStart(2, '0');
        const minutes = String(now.getMinutes()).padStart(2, '0');
        const seconds = String(now.getSeconds()).padStart(2, '0');

        // 엑셀 파일을 바이너리 형식으로 변환
        const buffer = await this.workbook.xlsx.writeBuffer();

        // Blob 생성 및 다운로드 트리거
        const blob = new Blob([buffer], { type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `경영실행${yyyymmdd}_${hours}${minutes}${seconds}.xlsx`;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        URL.revokeObjectURL(url);
      } catch (error) {
        console.error('엑셀 다운로드 오류:', error);
      }
    },
  },
};
</script>
