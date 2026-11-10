#!/usr/bin/env python3
"""
도우 결산 자동 점검용 DB 조회·드라이런 도구 — 무엇을 실행하든 마지막에 항상 ROLLBACK 한다(커밋 없음).

  사용: python -I scripts/auto_settle/dbq.py HQ|VN <sql파일> [--max-rows N]

  - HQ = 운영 DB 도우제조원가시스템 (application-prod2.yml), VN = DWCMSTEST (application.yml)
  - SQL 파일은 줄 하나에 '--;' 만 있는 줄로 문장을 나눈다. 각 문장의 결과셋을 모두 출력한다.
  - 모든 문장은 한 트랜잭션 안에서 실행되고 끝나면 ROLLBACK 한다.
    ALTER/CREATE OR ALTER 도 트랜잭션 안이므로 함께 되돌려진다 → 수정본 드라이런에 쓴다.
  - 접속정보는 설정 파일에서 읽는다(출력하지 않음).
"""

import os
import re
import sys

import pymssql

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
CONF = {
    "HQ": ("src/main/resources/application-prod2.yml", "도우제조원가시스템"),
    "VN": ("src/main/resources/application.yml", "DWCMSTEST"),
}


def load_conn(site):
    path, dbname = CONF[site]
    lines = open(os.path.join(ROOT, path), encoding="utf-8").read().splitlines()
    for i, line in enumerate(lines):
        if line.lstrip().startswith("#") or "url:" not in line or f"databaseName={dbname};" not in line:
            continue
        m = re.search(r"sqlserver://([^:;/]+):(\d+)", line)
        user = re.search(r"username:\s*(\S+)", lines[i + 1]).group(1)
        pw = re.search(r"password:\s*(\S+)", lines[i + 2]).group(1)
        return dict(server=m.group(1), port=int(m.group(2)), user=user, password=pw, database=dbname)
    raise SystemExit(f"{path} 에서 {dbname} 접속정보를 찾지 못함")


def main():
    sys.stdout.reconfigure(encoding="utf-8")
    if len(sys.argv) < 3 or sys.argv[1] not in CONF:
        raise SystemExit(__doc__)
    max_rows = int(sys.argv[sys.argv.index("--max-rows") + 1]) if "--max-rows" in sys.argv else 200
    sql = open(sys.argv[2], encoding="utf-8").read()
    conn = pymssql.connect(autocommit=False, **load_conn(sys.argv[1]))
    cur = conn.cursor()
    try:
        for n, stmt in enumerate(s for s in re.split(r"(?m)^--;\s*$", sql) if s.strip()):
            print(f"### [{n + 1}]")
            cur.execute(stmt)
            while True:
                if cur.description:
                    print([d[0] for d in cur.description])
                    rows = cur.fetchall()
                    for r in rows[:max_rows]:
                        print(r)
                    if len(rows) > max_rows:
                        print(f"... ({len(rows)}행 중 {max_rows}행만 표시)")
                if not cur.nextset():
                    break
    finally:
        conn.rollback()
        conn.close()
        print("### ROLLBACK (변경 없음)")


if __name__ == "__main__":
    main()
