# 로컬 개발 환경 구축 완료

## 📅 구축 일자
2025년 11월 3일

## 💻 시스템 환경
- **OS**: Ubuntu 24.04 LTS
- **아키텍처**: x86_64
- **사용자**: roarm_m3

---

## ✅ 설치 완료 항목

### 1. Java 개발 환경
- **Java 17**: `/home/roarm_m3/.jdk/jdk-17.0.16` (프로젝트 사용 버전)
- **Java 21**: `/usr/lib/jvm/java-21-openjdk-amd64` (향후 업그레이드 대비)
- **Maven**: 3.9.9 (Maven Wrapper 사용)

### 2. Node.js & 프론트엔드
- **Node.js**: v22.20.0
- **npm**: 10.9.3
- **Vue 의존성**: 설치 완료 (`src/main/vue/node_modules`)

### 3. IDE & 도구
- **VS Code**: 1.105.0
- **DBeaver**: 설치 완료

### 4. VPN
- **FortiClient VPN**: 7.4.3.1736
- **연결 상태**: dowoo VPN 연결됨
- **VPN IP**: 10.212.134.103

### 5. VS Code 확장 프로그램

**Java 개발:**
- ✅ Java Extension Pack
- ✅ Spring Boot Extension Pack
- ✅ Lombok (v1.1.1)
- ✅ Maven
- ✅ Debugger for Java
- ✅ Test Runner for Java

**Vue/JavaScript 개발:**
- ✅ Vetur
- ✅ Vue 3 Snippets
- ✅ Vue VSCode Snippets
- ✅ ESLint (v3.0.16)
- ✅ Prettier (v11.0.0)

**Git 도구:**
- ✅ GitLens
- ✅ Git History

**AI 도구:**
- ✅ GitHub Copilot
- ✅ GitHub Copilot Chat

---

## 🚀 애플리케이션 실행 방법

### 백엔드 (Spring Boot) 실행

```bash
cd /home/roarm_m3/dwisCOST
nohup ./mvnw spring-boot:run -Dspring-boot.run.profiles=local > /tmp/spring-boot.log 2>&1 &
```

**실행 정보:**
- **포트**: 9090
- **프로필**: local
- **URL**: http://localhost:9090
- **로그**: `/tmp/spring-boot.log`

### 프론트엔드 (Vue) 실행

```bash
cd /home/roarm_m3/dwisCOST/src/main/vue
npm run serve > /tmp/vue-dev.log 2>&1 &
```

**실행 정보:**
- **포트**: 4300
- **URL**: http://localhost:4300
- **네트워크**: http://172.30.1.54:4300
- **로그**: `/tmp/vue-dev.log`

### 서비스 중지

```bash
# 백엔드 중지
pkill -f spring-boot:run

# 프론트엔드 중지
pkill -f "npm run serve"

# 모든 서비스 중지
pkill -f "spring-boot:run" && pkill -f "npm run serve"
```

### 로그 실시간 확인

```bash
# 백엔드 로그
tail -f /tmp/spring-boot.log

# 프론트엔드 로그
tail -f /tmp/vue-dev.log
```

---

## 🗄️ 데이터베이스 연결 정보

### DEV 환경 (application-dev.yml)
```
서버: 172.16.200.204:1433
데이터베이스: 도우제조MES시스템TEST
사용자: TEST_MES_USER
비밀번호: Dowoo1!
```

### DEV1 환경 (application-dev1.yml)
```
서버: 172.16.200.204:1433
데이터베이스: dwisDev
사용자: dwisdev
비밀번호: Dowinsys0125
```

### DBeaver 연결 설정
1. Database: SQL Server
2. Server: `172.16.200.204`
3. Port: `1433`
4. Database: 위 환경별 DB 이름
5. Authentication: SQL Server
6. Username/Password: 위 정보 참조
7. 고급 설정:
   - ✅ Encrypt: true
   - ✅ Trust Server Certificate: true

---

## 🔐 로그인 정보

### 애플리케이션 테스트 계정

| 사용자 ID | 설명 | 권한/메뉴 |
|-----------|------|-----------|
| 230103-639 | 반장PC#1 | 메뉴 4개 |
| 230404-689 | 제조기술 | 메뉴 3개 |
| TEMP01 | Back#1 | 메뉴 2개 |
| 200120-97 | - | BIZADMIN 권한 |
| SYSADMIN | 시스템 관리자 | 전체 권한 |

**비밀번호**: 팀원에게 문의 (DB에 저장됨)

### Spring Security 기본 인증
```
사용자: dowinsysMES
비밀번호: Loved1113
```

---

## 🌐 VPN 연결 관리

### FortiClient VPN 상태 확인
```bash
forticlient vpn status
```

### VPN 연결
```bash
forticlient vpn connect dowoo
```

### VPN 연결 끊기
```bash
forticlient vpn disconnect
```

### VPN 서비스 관리
```bash
# 상태 확인
sudo systemctl status forticlient

# 재시작
sudo systemctl restart forticlient

# GUI 트레이 실행
/opt/forticlient/start-fortitray-launcher.sh
```

---

## 🔧 프로젝트 빌드

### 전체 빌드
```bash
cd /home/roarm_m3/dwisCOST
JAVA_HOME=/home/roarm_m3/.jdk/jdk-17.0.16 ./mvnw clean package
```

### 테스트 제외 빌드
```bash
./mvnw clean package -DskipTests
```

### 테스트 실행
```bash
./mvnw test
```

---

## 📦 프로젝트 구조

```
dwisCOST/
├── src/
│   ├── main/
│   │   ├── java/           # Spring Boot 백엔드 소스
│   │   │   └── com/dowinsys/
│   │   ├── resources/      # 설정 파일
│   │   │   ├── application.yml
│   │   │   ├── application-dev.yml
│   │   │   ├── application-dev1.yml
│   │   │   └── mapper/     # MyBatis XML
│   │   └── vue/            # Vue.js 프론트엔드
│   │       ├── src/
│   │       ├── package.json
│   │       └── vue.config.js
│   ├── sql/                # SQL 스크립트
│   └── test/               # 테스트 코드
├── pom.xml                 # Maven 설정
├── mvnw                    # Maven Wrapper
└── README.md
```

---

## 🎯 개발 워크플로우

### 1. 매일 개발 시작 시
```bash
# 1. VPN 연결 확인
forticlient vpn status

# 2. 최신 코드 Pull
git pull origin master

# 3. 백엔드 실행
cd /home/roarm_m3/dwisCOST
nohup ./mvnw spring-boot:run -Dspring-boot.run.profiles=local > /tmp/spring-boot.log 2>&1 &

# 4. 프론트엔드 실행
cd src/main/vue
npm run serve > /tmp/vue-dev.log 2>&1 &

# 5. 브라우저에서 확인
# http://localhost:4300
```

### 2. 개발 중
- 백엔드 코드 수정 → Spring Boot 자동 재시작 (DevTools 사용 시)
- 프론트엔드 코드 수정 → 자동 Hot Reload
- 로그 확인: `tail -f /tmp/spring-boot.log` 또는 `/tmp/vue-dev.log`

### 3. 개발 종료 시
```bash
# 서비스 중지
pkill -f spring-boot:run
pkill -f "npm run serve"

# 변경사항 커밋 (필요 시)
git add .
git commit -m "커밋 메시지"
# git push는 팀 확인 후 진행
```

---

## 💡 유용한 명령어

### Git 관련
```bash
# 현재 브랜치 확인
git branch

# 상태 확인
git status

# 변경사항 확인
git diff

# 로그 확인
git log --oneline -10
```

### 프로세스 확인
```bash
# 실행 중인 Java 프로세스
ps aux | grep java

# 실행 중인 Node 프로세스
ps aux | grep node

# 포트 사용 확인
netstat -tlnp | grep -E "9090|4300"
# 또는
ss -tlnp | grep -E "9090|4300"
```

### 시스템 리소스 확인
```bash
# CPU, 메모리 사용량
htop

# 디스크 사용량
df -h

# 특정 디렉토리 크기
du -sh /home/roarm_m3/dwisCOST
```

---

## ⚠️ 주의사항

### 1. Git 커밋/푸시
- **로컬 브랜치에서만 작업**
- 팀 확인 전까지 master에 직접 푸시 자제
- 필요 시 feature 브랜치 생성하여 작업

### 2. VPN 연결
- DB 접속 시 VPN 필수
- VPN 끊김 시 재연결: `forticlient vpn connect dowoo`

### 3. 포트 충돌
- 9090, 4300 포트가 이미 사용 중이면 애플리케이션 실행 실패
- 기존 프로세스 종료 후 재실행

### 4. 의존성 업데이트
```bash
# Maven 의존성 업데이트
./mvnw clean install

# npm 패키지 업데이트
cd src/main/vue
npm install
```

---

## 🔍 트러블슈팅

### 백엔드가 시작되지 않을 때
1. 로그 확인: `tail -100 /tmp/spring-boot.log`
2. 포트 확인: `netstat -tlnp | grep 9090`
3. Java 버전 확인: `java -version`
4. DB 연결 확인: VPN 연결 상태

### 프론트엔드가 시작되지 않을 때
1. 로그 확인: `tail -100 /tmp/vue-dev.log`
2. Node 버전 확인: `node --version`
3. 의존성 재설치: `cd src/main/vue && npm install`
4. 캐시 삭제: `rm -rf node_modules package-lock.json && npm install`

### VPN 연결 문제
1. 서비스 상태: `sudo systemctl status forticlient`
2. 서비스 재시작: `sudo systemctl restart forticlient`
3. 수동 연결: `forticlient vpn connect dowoo`

---

## 📞 도움이 필요할 때

### 팀 문의 사항
- 테스트 계정 비밀번호
- VPN 접속 정보
- DB 접근 권한
- 코드 리뷰 및 푸시 승인

### 유용한 문서
- Spring Boot 공식 문서: https://spring.io/projects/spring-boot
- Vue.js 공식 문서: https://vuejs.org/
- MyBatis 문서: https://mybatis.org/mybatis-3/

---

## ✨ 개발 환경 구축 완료!

모든 설정이 완료되었으며, 로컬 개발 환경에서 바로 작업을 시작할 수 있습니다.

**접속 URL:**
- 애플리케이션: http://localhost:4300
- API 서버: http://localhost:9090

**작성일**: 2025년 11월 3일
**구축자**: roarm_m3
