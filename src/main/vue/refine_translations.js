/**
 * 추출된 COST 텍스트를 정제하고 회계/원가 전문용어로 의역
 * 
 * 정제 규칙:
 * 1. 코드 조각/디버그 로그/주석 제거
 * 2. 템플릿 변수(${}), 코드 구문 제거
 * 3. 화면에 실제 표시되는 UI 텍스트만 남김
 * 4. 원가/회계 전문용어 의역 적용
 */

const fs = require('fs');
const path = require('path');

const inputFile = path.join(__dirname, 'src/assets/i18n/cost_only_terms.json');
const outputFile = path.join(__dirname, 'src/assets/i18n/ko_to_vi_v2.json');

const raw = JSON.parse(fs.readFileSync(inputFile, 'utf-8'));

// ========================================
// 1. 필터링 규칙: 제거 대상
// ========================================
function shouldRemove(text) {
  // 코드/디버그 패턴
  if (text.startsWith('[C00') || text.startsWith('[Tab') || text.startsWith('[M00')) return true;
  if (text.startsWith('[ERROR]') || text.startsWith('[MenuTabs]') || text.startsWith('[RealGrid]')) return true;
  if (text.startsWith('console.') || text.startsWith('/*') || text.startsWith('//')) return true;
  if (text.includes('${') || text.includes('item.')) return true;
  if (text.startsWith('{ ') || text.startsWith('} ')) return true;
  
  // CSS/코드 조각
  if (text.includes('width:') || text.includes('height:') || text.includes('padding:')) return true;
  if (text.includes('.vue') || text.includes('.js') || text.includes('.css')) return true;
  if (text.match(/^[a-zA-Z_$]/)) return true; // 영문으로 시작
  
  // 숫자/기호만
  if (!text.match(/[\uac00-\ud7af]/)) return true;
  
  // 너무 짧거나 의미 없는 패턴
  if (text.length === 1) return true;
  if (text.startsWith('-') && text.length <= 5) return true;
  if (text.startsWith('/') && !text.includes(' ')) return true;
  if (text.startsWith(',') || text.startsWith(';')) return true;
  
  // MES 전용 용어 (COST에서 사용 안 함)
  const mesTerms = ['CELL', 'CST', 'RUN NO', 'LOT NO', 'M-BOX', 'PACK', 'Pallet',
    '적층', '박리', 'UV', '히터', '모니터링 시료', '바코드', '출하검',
    '카세트', 'AGB', 'ORIGIN_NO', 'pkey', '공정코드', 'RunNo',
    '자동적층', '설미명'];
  for (const term of mesTerms) {
    if (text.includes(term)) return true;
  }

  return false;
}

// ========================================
// 2. 원가/회계 전문용어 의역 사전
// ========================================
const costTerms = {
  // === 핵심 원가/회계 용어 ===
  '원가': 'Giá thành',
  '원가결산': 'Quyết toán giá thành',
  '원가계산': 'Tính giá thành',
  '제조원가': 'Giá thành sản xuất',
  '매출원가': 'Giá vốn hàng bán',
  '재료비': 'Chi phí nguyên vật liệu',
  '노무비': 'Chi phí nhân công',
  '경비': 'Chi phí sản xuất chung',
  '제조경비': 'Chi phí sản xuất chung',
  '판매관리비': 'Chi phí bán hàng và quản lý',
  '판관비': 'Chi phí BH&QL',
  '감가상각비': 'Chi phí khấu hao',
  '감가상각': 'Khấu hao',
  
  // === 결산 관련 ===
  '결산': 'Quyết toán',
  '결산실행': 'Thực hiện quyết toán',
  '결산월': 'Tháng quyết toán',
  '월결산': 'Quyết toán tháng',
  '결산년월': 'Năm tháng quyết toán',
  '마감': 'Khóa sổ',
  '마감일': 'Ngày khóa sổ',
  
  // === 수불 관련 ===
  '수불': 'Nhập xuất',
  '수불부': 'Sổ nhập xuất',
  '제품수불': 'Nhập xuất thành phẩm',
  '재고수불': 'Nhập xuất tồn kho',
  '입고': 'Nhập kho',
  '출고': 'Xuất kho',
  '기초재고': 'Tồn kho đầu kỳ',
  '기말재고': 'Tồn kho cuối kỳ',
  '당기': 'Kỳ hiện tại',
  '전기': 'Kỳ trước',
  
  // === 배부 관련 ===
  '배부': 'Phân bổ',
  '배부표': 'Bảng phân bổ',
  '배부율': 'Tỷ lệ phân bổ',
  '배부기준': 'Tiêu chuẩn phân bổ',
  '원부자재': 'Nguyên phụ liệu',
  '원부자재 배부표': 'Bảng phân bổ nguyên phụ liệu',
  '가공비배부': 'Phân bổ chi phí gia công',
  '재료비배부': 'Phân bổ chi phí NVL',
  
  // === 생산 관련 ===
  '생산': 'Sản xuất',
  '생산실적': 'Thực tế sản xuất',
  '생산수량': 'Số lượng sản xuất',
  '생산정보': 'Thông tin sản xuất',
  '재공품': 'Bán thành phẩm',
  '재공': 'Bán thành phẩm',
  '완성품': 'Thành phẩm',
  '제품': 'Thành phẩm',
  '반제품': 'Bán thành phẩm',
  '부산물': 'Phụ phẩm',
  '공정': 'Công đoạn',
  '공정별': 'Theo công đoạn',
  
  // === 계정/재무 관련 ===
  '계정': 'Tài khoản',
  '계정코드': 'Mã tài khoản',
  '계정과목': 'Tài khoản kế toán',
  '계정별': 'Theo tài khoản',
  '차변': 'Nợ',
  '대변': 'Có',
  '잔액': 'Số dư',
  '매출': 'Doanh thu',
  '매출액': 'Doanh thu',
  '매입': 'Mua vào',
  '이익': 'Lợi nhuận',
  '영업이익': 'Lợi nhuận kinh doanh',
  '순이익': 'Lợi nhuận ròng',
  '손익': 'Lãi lỗ',
  '손익계산서': 'Báo cáo kết quả kinh doanh',
  
  // === 자재/품목 관련 ===
  '자재': 'Vật tư',
  '원자재': 'Nguyên vật liệu',
  '부자재': 'Phụ liệu',
  '소모품': 'Vật tư tiêu hao',
  '품목': 'Mặt hàng',
  '품목코드': 'Mã mặt hàng',
  '품명': 'Tên mặt hàng',
  '규격': 'Quy cách',
  '단위': 'Đơn vị',
  '단가': 'Đơn giá',
  '금액': 'Số tiền',
  '수량': 'Số lượng',
  
  // === 조직 관련 ===
  '부서': 'Phòng ban',
  '부서명': 'Tên phòng ban',
  '부서코드': 'Mã phòng ban',
  '부서별': 'Theo phòng ban',
  '공장': 'Nhà máy',
  '법인': 'Pháp nhân',
  '본사': 'Trụ sở chính',
  '비나': 'VINA',
  
  // === UI 공통 ===
  '조회': 'Tìm kiếm',
  '저장': 'Lưu',
  '삭제': 'Xóa',
  '추가': 'Thêm',
  '수정': 'Sửa',
  '취소': 'Hủy',
  '확인': 'Xác nhận',
  '닫기': 'Đóng',
  '실행': 'Thực hiện',
  '적용': 'Áp dụng',
  '엑셀': 'Excel',
  '엑셀 다운로드': 'Tải Excel',
  '다운로드': 'Tải xuống',
  '업로드': 'Tải lên',
  '초기화': 'Đặt lại',
  '새로고침': 'Làm mới',
  '인쇄': 'In ấn',
  '검색': 'Tìm kiếm',
  '선택': 'Chọn',
  '전체': 'Tất cả',
  '합계': 'Tổng cộng',
  '소계': 'Tiểu kế',
  '평균': 'Trung bình',
  '비율': 'Tỷ lệ',
  '비고': 'Ghi chú',
  '설명': 'Mô tả',
  '상세': 'Chi tiết',
  '목록': 'Danh sách',
  '등록': 'Đăng ký',
  '사용': 'Sử dụng',
  '미사용': 'Không sử dụng',
  
  // === 기간/날짜 ===
  '년': 'Năm',
  '월': 'Tháng',
  '일': 'Ngày',
  '년월': 'Năm tháng',
  '시작일': 'Ngày bắt đầu',
  '종료일': 'Ngày kết thúc',
  '기간': 'Kỳ',
  '당월': 'Tháng hiện tại',
  '전월': 'Tháng trước',
  '누계': 'Lũy kế',
  '연간': 'Hàng năm',
  
  // === 기준정보 ===
  '기준정보': 'Thông tin cơ bản',
  '원가기준정보': 'Thông tin cơ bản giá thành',
  '거래선코드': 'Mã đối tác',
  '거래선': 'Đối tác',
  '일반코드': 'Mã chung',
  '일반 코드': 'Mã chung',
  '코드': 'Mã',
  '코드명': 'Tên mã',
  '구분': 'Phân loại',
  '유형': 'Loại',
  '분류': 'Phân loại',
  
  // === 메뉴명 ===
  '시스템관리': 'Quản lý hệ thống',
  '사용자-메뉴 권한 관리': 'Quản lý quyền menu người dùng',
  '타시스템 I/F & Upload': 'Giao diện hệ thống & Tải lên',
  '원가레포트': 'Báo cáo giá thành',
  '경영계획': 'Kế hoạch kinh doanh',
  '경비집계': 'Tổng hợp chi phí',
  
  // === 보고서/레포트 ===
  '집계': 'Tổng hợp',
  '집계표': 'Bảng tổng hợp',
  '보고서': 'Báo cáo',
  '명세서': 'Bảng kê',
  '내역': 'Chi tiết',
  '현황': 'Hiện trạng',
  '실적': 'Thực tế',
  '예산': 'Ngân sách',
  '계획': 'Kế hoạch',
  '차이': 'Chênh lệch',
  '비교': 'So sánh',
  
  // === 환율 관련 ===
  '환율': 'Tỷ giá hối đoái',
  '환율관리': 'Quản lý tỷ giá',
  '환산': 'Quy đổi',
  '환산금액': 'Số tiền quy đổi',
  '통화': 'Tiền tệ',
  '원화': 'KRW',
  '달러': 'USD',
  '동': 'VND',
  
  // === 메시지 ===
  '저장하시겠습니까?': 'Bạn có muốn lưu không?',
  '삭제하시겠습니까?': 'Bạn có muốn xóa không?',
  '실행하시겠습니까?': 'Bạn có muốn thực hiện không?',
  '저장되었습니다.': 'Đã lưu thành công.',
  '삭제되었습니다.': 'Đã xóa thành công.',
  '실행되었습니다.': 'Đã thực hiện thành công.',
  '조회 결과가 없습니다.': 'Không có kết quả tìm kiếm.',
  '데이터가 없습니다.': 'Không có dữ liệu.',
  '필수 입력입니다.': 'Trường bắt buộc.',
  '처리중입니다.': 'Đang xử lý.',
  '오류가 발생했습니다.': 'Đã xảy ra lỗi.',
  '선택된 항목이 없습니다.': 'Không có mục được chọn.',
  
  // === 기타 원가 관련 ===
  '투입': 'Đầu vào',
  '산출': 'Đầu ra',
  '투입량': 'Lượng đầu vào',
  '산출량': 'Lượng đầu ra',
  '소요량': 'Định mức',
  '소요자재': 'Vật tư yêu cầu',
  '소요자재조회': 'Tra cứu vật tư yêu cầu',
  'BOM': 'BOM',
  '사용량': 'Lượng sử dụng',
  '재고': 'Tồn kho',
  '재고금액': 'Giá trị tồn kho',
  '이월': 'Chuyển kỳ',
  '기초금액': 'Số tiền đầu kỳ',
  '기말금액': 'Số tiền cuối kỳ',
  
  // === 사이트/언어 ===
  '사이트': 'Chi nhánh',
  '언어': 'Ngôn ngữ',
  '한국어': 'Tiếng Hàn',
  '베트남어': 'Tiếng Việt',
};

// ========================================
// 3. 정제 실행
// ========================================
console.log('=== COST 번역 정제 시작 ===\n');

const result = {};
let removed = 0;
let overridden = 0;
let kept = 0;

// 먼저 전문용어 사전 추가
for (const [ko, vi] of Object.entries(costTerms)) {
  result[ko] = vi;
}
console.log(`전문용어 사전: ${Object.keys(costTerms).length}개`);

// 추출된 텍스트 정제
for (const [ko, vi] of Object.entries(raw)) {
  if (shouldRemove(ko)) {
    removed++;
    continue;
  }

  // 전문용어 사전에 있으면 사전 번역 사용
  if (costTerms[ko]) {
    overridden++;
    continue; // 이미 추가됨
  }

  // 기존 번역이 있으면 유지
  if (vi && vi.length > 0) {
    result[ko] = vi;
    kept++;
  } else {
    // 미번역 항목도 일단 포함 (빈 값)
    result[ko] = '';
    kept++;
  }
}

// 정렬
const sorted = {};
Object.keys(result).sort((a, b) => a.localeCompare(b, 'ko')).forEach(k => {
  sorted[k] = result[k];
});

console.log(`\n=== 정제 결과 ===`);
console.log(`원본: ${Object.keys(raw).length}개`);
console.log(`제거: ${removed}개`);
console.log(`전문용어 교체: ${overridden}개`);
console.log(`유지: ${kept}개`);
console.log(`전문용어 추가: ${Object.keys(costTerms).length}개`);
console.log(`최종: ${Object.keys(sorted).length}개`);

// 미번역 항목 수
const untranslated = Object.entries(sorted).filter(([k, v]) => !v).length;
console.log(`미번역: ${untranslated}개`);

// 저장
fs.writeFileSync(outputFile, JSON.stringify(sorted, null, 2), 'utf-8');
console.log(`\n저장: ${outputFile}`);

// 통계
console.log('\n=== 카테고리별 통계 ===');
let catBtn = 0, catMsg = 0, catLabel = 0, catCost = 0, catOther = 0;
for (const k of Object.keys(sorted)) {
  if (k.match(/조회|저장|삭제|추가|수정|취소|닫기|확인|실행|적용|엑셀|다운|업로드|인쇄|검색|선택|초기화/)) catBtn++;
  else if (k.match(/하시겠습니까|되었습니다|없습니다|주세요|합니다$|입니다$/)) catMsg++;
  else if (k.match(/원가|결산|경비|배부|수불|재고|매출|재공|손익|집계|환율|감가/)) catCost++;
  else if (k.length <= 6) catLabel++;
  else catOther++;
}
console.log(`  버튼/액션: ${catBtn}개`);
console.log(`  메시지: ${catMsg}개`);
console.log(`  원가/회계 용어: ${catCost}개`);
console.log(`  라벨(짧은텍스트): ${catLabel}개`);
console.log(`  기타: ${catOther}개`);
