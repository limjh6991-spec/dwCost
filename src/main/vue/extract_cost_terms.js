/**
 * Vue 소스에서 한국어 텍스트를 추출하여 COST 전용 번역 JSON 생성
 * 
 * 추출 대상:
 * 1. .vue 파일의 template 영역 텍스트
 * 2. RealGrid 컬럼 헤더 (headerText, fieldName)  
 * 3. 버튼/라벨 텍스트
 * 4. 메뉴명 (DOI_CM_SYS_RESOURCE)
 * 5. 알림/확인 메시지
 */

const fs = require('fs');
const path = require('path');

const srcDir = path.join(__dirname, 'src');
const outputFile = path.join(__dirname, 'src/assets/i18n/cost_terms_extracted.json');

// 한국어 텍스트 매칭 정규식
const koreanRegex = /[\uac00-\ud7af\u1100-\u11ff\u3130-\u318f\ua960-\ua97f\ud7b0-\ud7ff]/;

// 추출된 텍스트 저장
const extractedTexts = new Set();

// 파일 재귀 탐색
function walkDir(dir, fileTypes) {
  const files = [];
  const items = fs.readdirSync(dir);
  for (const item of items) {
    const fullPath = path.join(dir, item);
    const stat = fs.statSync(fullPath);
    if (stat.isDirectory()) {
      if (item === 'node_modules' || item === 'dist' || item === '.git') continue;
      files.push(...walkDir(fullPath, fileTypes));
    } else if (fileTypes.some(ext => item.endsWith(ext))) {
      files.push(fullPath);
    }
  }
  return files;
}

// Vue template에서 한국어 텍스트 추출
function extractFromVueTemplate(content) {
  const texts = [];
  
  // 1. 순수 텍스트 노드 (태그 사이 텍스트)
  // <tag>한국어 텍스트</tag>
  const tagTextRegex = />([^<]*[\uac00-\ud7af][^<]*)</g;
  let match;
  while ((match = tagTextRegex.exec(content)) !== null) {
    const text = match[1].trim()
      .replace(/\{\{[^}]*\}\}/g, '')  // Vue 바인딩 제거
      .replace(/\s+/g, ' ')
      .trim();
    if (text && koreanRegex.test(text) && text.length >= 2 && text.length <= 50) {
      texts.push(text);
    }
  }

  // 2. placeholder 속성
  const placeholderRegex = /placeholder="([^"]*[\uac00-\ud7af][^"]*)"/g;
  while ((match = placeholderRegex.exec(content)) !== null) {
    texts.push(match[1].trim());
  }

  // 3. label 속성
  const labelRegex = /label="([^"]*[\uac00-\ud7af][^"]*)"/g;
  while ((match = labelRegex.exec(content)) !== null) {
    texts.push(match[1].trim());
  }

  // 4. title 속성
  const titleRegex = /title="([^"]*[\uac00-\ud7af][^"]*)"/g;
  while ((match = titleRegex.exec(content)) !== null) {
    texts.push(match[1].trim());
  }

  return texts;
}

// JS/Vue script에서 한국어 문자열 추출
function extractFromScript(content) {
  const texts = [];
  
  // 문자열 리터럴에서 한국어 추출
  const stringRegex = /['"`]([^'"`]*[\uac00-\ud7af][^'"`]*)['"`]/g;
  let match;
  while ((match = stringRegex.exec(content)) !== null) {
    const text = match[1].trim();
    if (text.length >= 2 && text.length <= 60 && !text.includes('http') && !text.includes('//')) {
      texts.push(text);
    }
  }

  return texts;
}

// RealGrid 컬럼 헤더 추출
function extractGridHeaders(content) {
  const texts = [];
  
  // headerText: '한국어'
  const headerRegex = /headerText\s*:\s*['"]([^'"]*[\uac00-\ud7af][^'"]*)['"]/g;
  let match;
  while ((match = headerRegex.exec(content)) !== null) {
    texts.push(match[1].trim());
  }

  // header: { text: '한국어' }
  const headerTextRegex = /header\s*:\s*\{[^}]*text\s*:\s*['"]([^'"]*[\uac00-\ud7af][^'"]*)['"]/g;
  while ((match = headerTextRegex.exec(content)) !== null) {
    texts.push(match[1].trim());
  }

  return texts;
}

console.log('=== COST 시스템 한국어 텍스트 추출 시작 ===\n');

// Vue 파일 처리
const vueFiles = walkDir(srcDir, ['.vue']);
console.log(`Vue 파일: ${vueFiles.length}개`);

let templateTexts = 0;
let scriptTexts = 0;
let gridTexts = 0;

for (const file of vueFiles) {
  const content = fs.readFileSync(file, 'utf-8');
  
  // Template 영역 추출
  const templateMatch = content.match(/<template>([\s\S]*?)<\/template>/);
  if (templateMatch) {
    const texts = extractFromVueTemplate(templateMatch[1]);
    texts.forEach(t => { extractedTexts.add(t); templateTexts++; });
  }

  // Script 영역 추출
  const scriptMatch = content.match(/<script[^>]*>([\s\S]*?)<\/script>/);
  if (scriptMatch) {
    const texts = extractFromScript(scriptMatch[1]);
    texts.forEach(t => { extractedTexts.add(t); scriptTexts++; });
    
    const headers = extractGridHeaders(scriptMatch[1]);
    headers.forEach(t => { extractedTexts.add(t); gridTexts++; });
  }
}

// JS 파일 처리 (router, store 등)
const jsFiles = walkDir(srcDir, ['.js']);
console.log(`JS 파일: ${jsFiles.length}개`);

for (const file of jsFiles) {
  if (file.includes('node_modules') || file.includes('exceljs')) continue;
  const content = fs.readFileSync(file, 'utf-8');
  const texts = extractFromScript(content);
  texts.forEach(t => extractedTexts.add(t));
}

// 결과 정리
const sorted = [...extractedTexts].sort((a, b) => a.localeCompare(b, 'ko'));

console.log(`\n=== 추출 결과 ===`);
console.log(`Template 텍스트: ${templateTexts}회`);
console.log(`Script 문자열: ${scriptTexts}회`);
console.log(`Grid 헤더: ${gridTexts}회`);
console.log(`고유 텍스트: ${sorted.length}개`);

// 기존 ko_to_vi.json에서 매칭
const existingFile = path.join(__dirname, 'src/assets/i18n/ko_to_vi.json');
let existingTranslations = {};
if (fs.existsSync(existingFile)) {
  existingTranslations = JSON.parse(fs.readFileSync(existingFile, 'utf-8'));
  console.log(`기존 번역: ${Object.keys(existingTranslations).length}개`);
}

// 매칭 결과
let matched = 0;
let unmatched = 0;
const result = {};

for (const text of sorted) {
  if (existingTranslations[text]) {
    result[text] = existingTranslations[text];
    matched++;
  } else {
    result[text] = '';  // 미번역
    unmatched++;
  }
}

console.log(`기존 번역 매칭: ${matched}개`);
console.log(`미번역 (신규): ${unmatched}개`);

// JSON 저장
fs.writeFileSync(outputFile, JSON.stringify(result, null, 2), 'utf-8');
console.log(`\n저장: ${outputFile}`);
console.log(`최종 항목 수: ${Object.keys(result).length}개`);

// 카테고리별 분류 통계
const categories = {
  menu: [],
  button: [],
  label: [],
  grid: [],
  message: [],
  other: []
};

for (const text of sorted) {
  if (text.match(/조회|저장|삭제|추가|수정|취소|닫기|확인|엑셀|다운|업로드|실행|적용/)) {
    categories.button.push(text);
  } else if (text.match(/하시겠습니까|되었습니다|없습니다|주세요|합니다$/)) {
    categories.message.push(text);
  } else if (text.length <= 6 && !text.includes(' ')) {
    categories.label.push(text);
  } else {
    categories.other.push(text);
  }
}

console.log('\n=== 카테고리별 분류 ===');
for (const [cat, items] of Object.entries(categories)) {
  console.log(`  ${cat}: ${items.length}개`);
}
