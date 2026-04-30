#!/bin/bash
set -e

echo "----------------------------------------------------"
echo "🚀 [업데이트 안내]"
echo "  - ✅ GitHub의 GnuBoard7 저장소에서 최신 버전을 가져와 업데이트합니다"
echo "  - ℹ️  Docker image 버전(PHP/Node/MySQL 등)은 docker-compose.yml / Dockerfile에서 직접 관리하세요"
echo "----------------------------------------------------"

# 1. Load only APP_NAME safely (.env may contain reserved vars like UID on macOS)
PROJECT_NAME=$(grep '^PROJECT_NAME=' .env 2>/dev/null | cut -d '=' -f2 | tr -d '"')
PROJECT_NAME=${PROJECT_NAME:-g7}
DOCKER_COMPOSE="docker compose -p ${PROJECT_NAME}"

echo "🔍 [${PROJECT_NAME}] 버전 체크를 시작합니다..."

# 2. Safety checks
git config --global --add safe.directory "*" || true

if [ ! -d "./g7" ]; then
    echo "❌ Error: ./g7 directory does not exist."
    exit 1
fi

# 3. Fetch latest remote
cd ./g7
echo "📡 원격 저장소에서 최신 정보를 가져오는 중..."
git fetch origin main > /dev/null 2>&1

LOCAL_HASH=$(git rev-parse HEAD)
REMOTE_HASH=$(git rev-parse @{u})

if [ "$LOCAL_HASH" = "$REMOTE_HASH" ]; then
    echo "----------------------------------------------------"
    echo "✅ 프로젝트 [${PROJECT_NAME}]는 이미 최신 버전입니다."
    echo "----------------------------------------------------"
    exit 0
fi

cd ..

# 4. Ask update mode
echo "📢 새로운 업데이트가 발견되었습니다!"
echo "----------------------------------------------------"
echo "❓ 업데이트 방식을 선택해주세요."
echo "   y: 운영(Production) 모드 - 이미지 재빌드 후 컨테이너 교체 (권장)"
echo "   n: 개발(Development) 모드 - 실행 중인 컨테이너 내부에서 소스만 갱신"
echo "----------------------------------------------------"
read -p "이미지를 다시 빌드하시겠습니까? (y/n): " answer

# 5. Pull latest source
echo "ℹ️ 최신 소스 코드를 적용합니다 (git pull)..."
cd ./g7
git pull
cd ..

# 6. Apply update
if [[ "$answer" =~ ^[Yy]$ ]]; then
    echo "🏗️ 운영 모드: 이미지를 재빌드하고 컨테이너를 교체합니다..."
    $DOCKER_COMPOSE build g7_app
    $DOCKER_COMPOSE up -d g7_app
    echo "✅ 이미지 빌드 및 컨테이너 교체 완료."
else
    echo "⚡ 개발 모드: 실행 중인 컨테이너에서 의존성을 갱신합니다..."
    $DOCKER_COMPOSE exec -t g7_app composer install
fi

# 7. Post-update tasks
echo "🧹 후속 작업 실행 중..."

$DOCKER_COMPOSE exec -t g7_app php artisan core:update --source=.
$DOCKER_COMPOSE exec -t g7_app php artisan migrate --force
$DOCKER_COMPOSE exec -t g7_app php artisan optimize:clear
$DOCKER_COMPOSE exec -t g7_app chown -R app:app storage bootstrap/cache

echo "----------------------------------------------------"
echo "✨ 업데이트 완료! 현재 버전: $($DOCKER_COMPOSE exec -t g7_app php artisan --version)"
echo "🚀 [${PROJECT_NAME}] 프로젝트의 모든 작업이 성공적으로 마무리되었습니다."
echo "----------------------------------------------------"
echo ""
echo "💡 웹 브라우저에서 새로고침하여 확인하세요."
echo "⚠️  문제가 발생할 경우 아래 명령어를 시도해보세요:"
echo "   $DOCKER_COMPOSE restart g7_app"
echo ""