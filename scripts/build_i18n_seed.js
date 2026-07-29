const fs = require('fs');
const path = require('path');

const jsonPath = path.join(__dirname, '../src/main/vue/src/assets/i18n/ko_to_vi.json');
const sqlPath = path.join(__dirname, '../db/seed_doi_i18n.sql');

const tr = JSON.parse(fs.readFileSync(jsonPath, 'utf8'));

function escapeSql(str) {
  if (!str) return '';
  return str.replace(/'/g, "''");
}

let lines = [
  '-- =========================================',
  '-- DOI_I18N 데이터 시드 스크립트 (총 ' + Object.keys(tr).length + '건)',
  '-- DWCMSTEST.dbo.DOI_I18N 테이블용',
  '-- =========================================',
  '',
  "IF OBJECT_ID('dbo.DOI_I18N', 'U') IS NULL",
  'BEGIN',
  '    CREATE TABLE dbo.DOI_I18N (',
  '        LANG_KEY NVARCHAR(500) NOT NULL,',
  '        KO_TEXT  NVARCHAR(MAX) NULL,',
  '        VI_TEXT  NVARCHAR(MAX) NULL,',
  "        USE_YN   VARCHAR(1) DEFAULT 'Y',",
  '        INIT_DT  DATETIME DEFAULT GETDATE()',
  '    );',
  'END;',
  'GO',
  ''
];

let cnt = 0;
let entries = Object.entries(tr);

lines.push('BEGIN TRANSACTION;');

for (let i = 0; i < entries.length; i++) {
  const [k, v] = entries[i];
  const ek = escapeSql(k);
  const ev = escapeSql(v);

  lines.push(`IF EXISTS (SELECT 1 FROM dbo.DOI_I18N WHERE LANG_KEY = N'${ek}') UPDATE dbo.DOI_I18N SET VI_TEXT = N'${ev}', KO_TEXT = N'${ek}' WHERE LANG_KEY = N'${ek}'; ELSE INSERT INTO dbo.DOI_I18N (LANG_KEY, KO_TEXT, VI_TEXT, USE_YN, INIT_DT) VALUES (N'${ek}', N'${ek}', N'${ev}', 'Y', GETDATE());`);

  cnt++;
  if (cnt % 200 === 0) {
    lines.push('COMMIT TRANSACTION;');
    lines.push('GO');
    lines.push('BEGIN TRANSACTION;');
  }
}

lines.push('COMMIT TRANSACTION;');
lines.push('GO');

fs.writeFileSync(sqlPath, lines.join('\n'), 'utf8');
console.log('Successfully generated ' + sqlPath + ' with ' + entries.length + ' entries.');
