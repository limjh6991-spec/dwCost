/**
 * COST 전용 Vue 뷰(c0001~c0009)에서만 한국어 텍스트 추출
 * + 공통 컴포넌트/레이아웃 포함
 */

const fs = require('fs');
const path = require('path');

const vueDir = path.join(__dirname, 'src');
const outputFile = path.join(__dirname, 'src/assets/i18n/cost_only_terms.json');

const koreanRegex = /[\uac00-\ud7af]/;

const extractedTexts = new Set();

function walkDir(dir, fileTypes) {
  const files = [];
  if (!fs.existsSync(dir)) return files;
  const items = fs.readdirSync(dir);
  for (const item of items) {
    const fullPath = path.join(dir, item);
    const stat = fs.statSync(fullPath);
    if (stat.isDirectory()) {
      if (item === 'node_modules' || item === 'dist') continue;
      files.push(...walkDir(fullPath, fileTypes));
    } else if (fileTypes.some(ext => item.endsWith(ext))) {
      files.push(fullPath);
    }
  }
  return files;
}

function extractKoreanStrings(content) {
  const texts = new Set();
  
  // 문자열 리터럴
  const regex = /['"`]([^'"`\n]*[\uac00-\ud7af][^'"`\n]*)['"`]/g;
  let match;
  while ((match = regex.exec(content)) !== null) {
    let text = match[1].trim();
    if (text.length >= 1 && text.length <= 60 && !text.includes('http') && !text.includes('//') && !text.startsWith('import')) {
      // Clean up
      text = text.replace(/\\n/g, '').replace(/\\t/g, '').trim();
      if (text && koreanRegex.test(text)) {
        texts.add(text);
      }
    }
  }

  // 태그 사이 텍스트
  const tagRegex = />([^<]*[\uac00-\ud7af][^<]*)</g;
  while ((match = tagRegex.exec(content)) !== null) {
    let text = match[1].trim()
      .replace(/\{\{[^}]*\}\}/g, '')
      .replace(/\s+/g, ' ')
      .trim();
    if (text && koreanRegex.test(text) && text.length >= 1 && text.length <= 50) {
      texts.add(text);
    }
  }

  // placeholder/label/title 속성
  const attrRegex = /(?:placeholder|label|title|header-text)="([^"]*[\uac00-\ud7af][^"]*)"/g;
  while ((match = attrRegex.exec(content)) !== null) {
    texts.add(match[1].trim());
  }

  // headerText: '...'
  const headerRegex = /headerText\s*:\s*['"]([^'"]*[\uac00-\ud7af][^'"]*)['"]/g;
  while ((match = headerRegex.exec(content)) !== null) {
    texts.add(match[1].trim());
  }

  return texts;
}

console.log('=== COST 전용 한국어 텍스트 추출 ===\n');

// 1. COST 전용 뷰 (c0001~c0009)
const costViewDirs = [
  'views/web/c0001000', 'views/web/c0003000', 'views/web/c0007000',
  'views/web/c0008000', 'views/web/c0009000', 'views/web/popup',
  'views/web/store'
];
let costViewCount = 0;
for (const dir of costViewDirs) {
  const fullDir = path.join(vueDir, dir);
  const files = walkDir(fullDir, ['.vue', '.js']);
  for (const f of files) {
    const content = fs.readFileSync(f, 'utf-8');
    extractKoreanStrings(content).forEach(t => extractedTexts.add(t));
    costViewCount++;
  }
}
console.log(`COST 뷰 파일: ${costViewCount}개`);

// 2. 공통 컴포넌트
const commonDirs = ['components', 'layouts', 'utils'];
let commonCount = 0;
for (const dir of commonDirs) {
  const fullDir = path.join(vueDir, dir);
  const files = walkDir(fullDir, ['.vue', '.js']);
  for (const f of files) {
    const content = fs.readFileSync(f, 'utf-8');
    extractKoreanStrings(content).forEach(t => extractedTexts.add(t));
    commonCount++;
  }
}
console.log(`공통 컴포넌트: ${commonCount}개`);

// 3. App.vue, main.js
for (const f of ['App.vue', 'main.js']) {
  const fullPath = path.join(vueDir, f);
  if (fs.existsSync(fullPath)) {
    const content = fs.readFileSync(fullPath, 'utf-8');
    extractKoreanStrings(content).forEach(t => extractedTexts.add(t));
  }
}

// 4. 라우터
const routerDir = path.join(vueDir, 'router');
const routerFiles = walkDir(routerDir, ['.js']);
for (const f of routerFiles) {
  const content = fs.readFileSync(f, 'utf-8');
  extractKoreanStrings(content).forEach(t => extractedTexts.add(t));
}

// 필터링: 너무 짧거나 코드 조각 제거
const filtered = [...extractedTexts].filter(text => {
  // 한 글자 한국어 제거 (의미 없음)
  if (text.length === 1) return false;
  // 코드/변수명 패턴 제거
  if (text.match(/^[a-zA-Z_$]/)) return false;
  // 주석/디버그 로그 제거
  if (text.startsWith('console.') || text.startsWith('//')) return false;
  // 파일 경로 제거
  if (text.includes('/') && text.includes('.')) return false;
  return true;
});

const sorted = filtered.sort((a, b) => a.localeCompare(b, 'ko'));
console.log(`\n추출된 고유 텍스트: ${sorted.length}개`);

// 기존 번역 매칭
const existingFile = path.join(__dirname, 'src/assets/i18n/ko_to_vi.json');
const existing = JSON.parse(fs.readFileSync(existingFile, 'utf-8'));

let matched = 0, unmatched = 0;
const result = {};
const unmatchedList = [];

for (const text of sorted) {
  if (existing[text]) {
    result[text] = existing[text];
    matched++;
  } else {
    result[text] = ''; // 미번역
    unmatched++;
    unmatchedList.push(text);
  }
}

console.log(`기존 번역 매칭: ${matched}개`);
console.log(`미번역: ${unmatched}개`);

// 저장
fs.writeFileSync(outputFile, JSON.stringify(result, null, 2), 'utf-8');
console.log(`\n저장: ${outputFile}`);
console.log(`최종: ${Object.keys(result).length}개 (기존 ${Object.keys(existing).length}개에서 축소)`);

// 미번역 항목 출력
if (unmatchedList.length > 0 && unmatchedList.length <= 100) {
  console.log('\n=== 미번역 항목 ===');
  unmatchedList.forEach(t => console.log(`  "${t}"`));
}

// 카테고리 분석
console.log('\n=== 샘플: 처음 50개 항목 ===');
sorted.slice(0, 50).forEach(t => {
  const vi = result[t] || '(미번역)';
  console.log(`  "${t}" -> "${vi}"`);
});
