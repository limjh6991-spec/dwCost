/**
 * 1차 데이터(DOI_I18N)에서 순수 한국어 단어만 추출하여 2차 사전(DOI_I18N_DICT) 생성
 * 
 * 로직:
 * 1. DOI_I18N의 KO_TEXT에서 한국어 부분만 추출
 * 2. 공백 기준 토큰화 + 연속 한국어 추출
 * 3. 중복 제거
 * 4. 기존 번역이 있으면 매칭
 * 5. DOI_I18N_DICT 테이블에 INSERT
 */

const fs = require('fs');
const path = require('path');

// 1차 데이터 로드 (ko_to_vi_v2.json)
const v2File = path.join(__dirname, 'src/assets/i18n/ko_to_vi_v2.json');
const rawData = JSON.parse(fs.readFileSync(v2File, 'utf-8'));

console.log(`=== 1차 데이터: ${Object.keys(rawData).length}건 ===\n`);

// 한국어 추출 정규식: 연속된 한국어+공백 그룹
const koreanGroupRegex = /[\uac00-\ud7af][\uac00-\ud7af\s]*/g;

// 순수 한국어 단어/구문 추출
const dictMap = new Map(); // word -> { count, sources, existingVi }

for (const [koText, viText] of Object.entries(rawData)) {
  // 원문 그대로도 사전에 추가 (정확 매칭용)
  const trimmed = koText.trim();
  
  // 한국어 그룹 추출
  const matches = trimmed.match(koreanGroupRegex);
  if (!matches) continue;
  
  for (let match of matches) {
    match = match.trim();
    if (match.length < 2) continue; // 1글자 제외
    
    // 이미 있으면 카운트 증가
    if (dictMap.has(match)) {
      const entry = dictMap.get(match);
      entry.count++;
      entry.sources.add(koText);
    } else {
      dictMap.set(match, {
        count: 1,
        sources: new Set([koText]),
        existingVi: ''
      });
    }
    
    // 공백으로 분리된 하위 단어도 추출
    if (match.includes(' ')) {
      const subWords = match.split(/\s+/).filter(w => w.length >= 2);
      for (const sub of subWords) {
        if (dictMap.has(sub)) {
          dictMap.get(sub).count++;
          dictMap.get(sub).sources.add(koText);
        } else {
          dictMap.set(sub, {
            count: 1,
            sources: new Set([koText]),
            existingVi: ''
          });
        }
      }
    }
  }
}

// 기존 번역 매칭 (v2에서)
for (const [word, entry] of dictMap.entries()) {
  // 정확히 일치하는 번역 찾기
  if (rawData[word] && rawData[word].length > 0) {
    entry.existingVi = rawData[word];
  }
}

// 정렬: 빈도 높은 순 + 가나다 순
const sorted = [...dictMap.entries()]
  .sort((a, b) => b[1].count - a[1].count || a[0].localeCompare(b[0], 'ko'));

// 통계
const total = sorted.length;
const withTranslation = sorted.filter(([, e]) => e.existingVi).length;
const without = total - withTranslation;

console.log(`=== 2차 사전 (DICT) 추출 결과 ===`);
console.log(`  총 고유 단어/구문: ${total}개`);
console.log(`  번역 있음: ${withTranslation}개`);
console.log(`  미번역: ${without}개`);
console.log(`  1차 대비 감소율: ${((1 - total / Object.keys(rawData).length) * 100).toFixed(0)}%`);

// 빈도 TOP 30
console.log(`\n=== 빈도 TOP 30 ===`);
sorted.slice(0, 30).forEach(([word, entry]) => {
  const vi = entry.existingVi || '(미번역)';
  console.log(`  [${entry.count}회] "${word}" -> "${vi}"`);
});

// 2차 사전 JSON 생성
const dictJson = {};
for (const [word, entry] of sorted) {
  dictJson[word] = entry.existingVi || '';
}

const dictFile = path.join(__dirname, 'src/assets/i18n/dict_v1.json');
fs.writeFileSync(dictFile, JSON.stringify(dictJson, null, 2), 'utf-8');
console.log(`\n사전 저장: ${dictFile}`);
console.log(`사전 크기: ${(fs.statSync(dictFile).size / 1024).toFixed(1)}KB (v2: ${(fs.statSync(v2File).size / 1024).toFixed(1)}KB)`);

// SQL 생성 (DOI_I18N_DICT 테이블 생성 + INSERT)
const sqlFile = path.join(__dirname, 'src/assets/i18n/create_dict_table.sql');
let sql = `-- DOI_I18N_DICT 테이블 생성\n`;
sql += `IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'DOI_I18N_DICT')\n`;
sql += `BEGIN\n`;
sql += `  CREATE TABLE DOI_I18N_DICT (\n`;
sql += `    SEQ INT NOT NULL,\n`;
sql += `    KO_WORD NVARCHAR(200) NOT NULL,\n`;
sql += `    VI_WORD NVARCHAR(500) NOT NULL DEFAULT '',\n`;
sql += `    FREQUENCY INT DEFAULT 1,\n`;
sql += `    CATEGORY NVARCHAR(50) DEFAULT 'COMMON',\n`;
sql += `    USE_YN CHAR(1) DEFAULT 'Y',\n`;
sql += `    REG_DATE DATETIME DEFAULT GETDATE(),\n`;
sql += `    UPD_DATE DATETIME NULL,\n`;
sql += `    CONSTRAINT PK_DOI_I18N_DICT PRIMARY KEY (SEQ)\n`;
sql += `  );\n`;
sql += `  CREATE UNIQUE INDEX UX_DOI_I18N_DICT_KO ON DOI_I18N_DICT(KO_WORD);\n`;
sql += `END;\n\n`;

sql += `-- 기존 데이터 삭제\nDELETE FROM DOI_I18N_DICT;\n\n`;
sql += `-- 사전 데이터 INSERT\n`;

let seq = 1;
for (const [word, entry] of sorted) {
  const vi = (entry.existingVi || '').replace(/'/g, "''");
  const ko = word.replace(/'/g, "''");
  sql += `INSERT INTO DOI_I18N_DICT (SEQ, KO_WORD, VI_WORD, FREQUENCY) VALUES (${seq++}, N'${ko}', N'${vi}', ${entry.count});\n`;
}

fs.writeFileSync(sqlFile, sql, 'utf-8');
console.log(`SQL 저장: ${sqlFile}`);
