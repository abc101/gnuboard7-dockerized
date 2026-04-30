#!/bin/bash
# 0. 그누보드가 존재하는지 확인 - 질의 응답은 터미널의 호환성을 위해 영어로 유지
if [ -d "g7" ]; then
    echo "‼️ GnuBoard 7 directory already exists."
    read -p "❔ Do you want to remove it and re-install? (y/n): " answer
    
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        echo "🗑️ Removing existing GnuBoard 7 directory..."
        
        # 기존 디렉토리를 삭제할 때 권한 문제를 방지하기 위해 sudo 사용 여부 확인
        if [ "$EUID" -ne 0 ]; then
            sudo rm -rf g7
        else
            rm -rf g7
        fi

        # 삭제가 성공적으로 이루어졌는지 확인
        if [ -d "g7" ]; then
            echo "❌ Failed to remove the directory. Please check permissions."
            exit 1
        fi
        echo "✅ Successfully removed. Proceeding with installation."
        
    else
        echo "🛑 Your answer is No. Installation skipped by user."
        exit 0
    fi
else
    echo "✅ GnuBoard 7 directory does not exist. Proceeding with installation."
fi

# 1. GnuBoard 7 다운로드 (Git clone)
echo "ℹ️ Downloading GnuBoard 7..."
# Git clone with error handling
git clone https://github.com/gnuboard/g7.git g7 || { echo "❌ Git clone failed. Please check your network or URL."; exit 1; }
echo "✅ Download complete."

# 2. Docker 이미지 빌드
echo "⚒️ Building Docker containers (this may take a while)..."
docker compose build || { echo "❌ Docker build failed."; exit 1; }
echo "✅ Build complete."

# 3. 권한 설정 (storage 및 cache 디렉토리)
echo "📂 Setting permissions for storage and cache..."
# Create necessary directories and set permissions (use sudo if not running as root)
mkdir -p g7/storage/framework/{sessions,views,cache/data} g7/bootstrap/cache
chmod -R 775 g7/storage g7/bootstrap/cache
echo "✅ Permissions set."

# 4. Docker 컨테이너 실행
echo "🚀 Starting Docker containers..."
docker compose up -d || { echo "❌ Failed to start Docker containers."; exit 1; }

# 5. 마무리 작업 (Migration & Cache)
echo "----------------------------------------------------"
echo "✅ Success! GnuBoard 7 is now up and running."
echo "💡 You can check the logs using: docker compose logs -f"
echo "----------------------------------------------------"
