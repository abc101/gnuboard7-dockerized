
# GnuBoard 7 Dockerized Setup

이 프로젝트는 **[그누보드7(GnuBoard 7)](https://github.com/gnuboard/g7)** 을 도커(Docker) 환경에서 쉽고 빠르게 배포하고 운영하기 위해 구성된 자동화 환경입니다. 
호스트 볼륨 연결 시 발생하는 리눅스 파일 권한(Permission) 문제를 완벽하게 해결했으며, Cloudflare 및 NPM (Nginx Proxy Manager) 환경에서도 실제 방문자 IP를 정확하게 추적할 수 있도록 최적화되어 있습니다. 

## ✨ 주요 기능 및 특징

* **원클릭 자동 설치:** `installer.sh` 스크립트를 통해 그누보드7 소스 코드 다운로드, 의존성 설치, 도커 컨테이너 빌드 및 권한 설정까지 한번에 진행됩니다.
* **프록시 및 Cloudflare 완벽 호환:** 삼중 프록시(Cloudflare -> NPM -> Docker) 환경에서도 `CF-Connecting-IP` 헤더를 통해 실제 사용자의 IP를 정확히 인식하도록 Nginx가 구성되어 있습니다.
* **최신 환경 최적화:** PHP 8.3 FPM과 Node.js 20을 기반으로 구동되며, Redis, Imagick, Memcached 등의 필수 확장 모듈이 내장되어 있습니다.
* **Redis 캐시 및 세션 적용:** 파일 기반 세션으로 인한 권한 꼬임 현상을 방지하고 속도를 향상시키기 위해 기본적으로 Redis를 세션 및 캐시 스토어로 사용합니다.
* **간편한 코어 업데이트:** `update.sh` 스크립트 하나로 그누보드7 코어 업데이트, 패키지 동기화, 캐시 초기화 작업이 자동으로 진행됩니다.

## 📂 파일 구조
* `conf/nginx.conf`: Nginx Proxy Manageer(NPM)등 Nginx 웹 서버 설정 및 리버스 프록시 IP 추적(Cloudflare 설정)을 담당합니다. **본인의 서버에 환경에 맞게 수정해서 사용하시기 바랍니다.**
* `conf/uoloads.ini`: PHP max file upload size용 설정 화일입니다.  **본인의 서버에 환경에 맞게 수정해서 사용하시기 바랍니다.**
* `docker-compose.yml`: PHP-FPM, Nginx, MariaDB, Redis 컨테이너를 구동하는 메인 스택 설정 파일입니다.
* `Dockerfile`: 그누보드7 구동에 필요한 PHP 확장 모듈과 Composer, Node.js가 포함된 커스텀 PHP 8.3 이미지 빌드 파일입니다.
* `example.env`: 데이터베이스, Redis, 포트 및 유저 권한이 정의된 환경변수 템플릿입니다.
* `entrypoint.sh`: 컨테이너 실행 시 컴포저(Composer) 패키지 설치 유무를 확인하고, 라라벨 환경변수를 주입하는 시작 스크립트입니다.
* `installer.sh`: 그누보드7 최초 설치 및 도커 환경 구축을 자동화하는 스크립트입니다.
* `update.sh`: 그누보드7 코어 소스 및 패키지를 안전하게 최신 버전으로 업데이트하는 스크립트입니다.

## 🚀 시작하기 (설치 방법)

### 1. 사전 준비
서버에 **Docker**와 **Docker Compose(Docker Engine 20.10.x 이상)**, 그리고 **Git**이 설치되어 있어야 합니다.

### 2. 레포지토리 클론 및 환경 설정
```bash
# 본 레포지토리를 클론합니다.
git clone https://github.com/abc101/gnuboard7-dockerized.git [사용자 프로잭트 네임]
cd [사용자 프로잭트 네임]

# 환경 변수 파일을 복사하여 생성합니다.
cp example.env .env

# .env 파일을 열어 비밀번호, 포트 등을 환경에 맞게 수정합니다.
nano .env
```
*(주의: `DB_ROOT_PASSWORD`, `DB_PASSWORD`, `REDIS_PASSWORD`는 반드시 안전한 비밀번호로 변경하세요.)* 

### 3. 설치 스크립트 실행
스크립트에 실행 권한을 부여하고 인스톨러를 실행합니다.
```bash
chmod +x installer.sh update.sh entrypoint.sh
./installer.sh
```

설치가 완료되면 `http://서버IP:설정한포트` 로 접속하여 그누보드7 화면을 확인할 수 있습니다.

## 🔄 업데이트 방법 (Update Guide)

프로젝트 루트에서 제공되는 `update.sh`를 실행하면 환경에 맞는 업데이트를 진행할 수 있습니다.

```bash
chmod +x update.sh
./update.sh
```
- **운영 환경(Production) 업데이트 (y 선택)**: 이미지를 새로 빌드하고 컨테이너를 교체합니다. 가장 안전하며 서비스 배포시 권장되는 방식입니다.

- **개발 환경(Development) 업데이트 (n 선택)**: 개발 환경에서 기존 컨테이너 교체 없이 내부 소스와 패키지만 빠르게 갱신하고 기존 컨테이너 이미지를 유지 하고 싶을때 사용하는 방식입니다. 

## 🛠️ 트러블슈팅 (FAQ)

**Q. 웹 브라우저 접속 시 `502 Bad Gateway`가 뜹니다.**
> 최초 설치 시 백그라운드에서 `composer install`이 진행 중일 수 있습니다. 터미널에서 `docker compose logs -f g7_app` 명령어를 입력하여 패키지 설치가 완료되었는지 확인해 주세요. 시스템에 따라 1-2분 정도의 소요시간이 필요합니다.

**Q. 관리자 페이지에서 접속자 IP가 서버 내부 IP(예: 10.x.x.x)로 보입니다.**
> 본 구성은 Cloudflare를 통과한 트래픽에 맞춰 `CF-Connecting-IP`를 인식하도록 세팅되어 있습니다. 만약 Cloudflare를 사용하지 않고 Nginx Proxy Manager만 단독으로 사용하신다면, `nginx.conf`에서 `real_ip_header CF-Connecting-IP;` 부분을 `real_ip_header X-Forwarded-For;` 로 변경한 뒤 Nginx를 재시작(`docker compose restart g7_web`)해 주세요.

---
**License**
이 프로젝트는 MIT License를 따릅니다. 그누보드7의 코어 소스코드는 해당 소프트웨어의 라이선스 정책을 따릅니다.