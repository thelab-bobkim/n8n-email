
#!/bin/bash

set -e



RED='\033[0;31m'

GREEN='\033[0;32m'

YELLOW='\033[1;33m'

BLUE='\033[0;34m'

NC='\033[0m'



echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo -e "${GREEN}������ n8n 계약갱신 자동알림 시스템 설치${NC}"

echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo ""



# Docker 설치 확인

echo -e "${BLUE}[1/6]${NC} Docker 확인 중..."

if ! command -v docker &> /dev/null; then

    echo -e "${YELLOW}Docker가 없습니다. 설치 중...${NC}"

    curl -fsSL https://get.docker.com -o get-docker.sh

    sudo sh get-docker.sh

    sudo usermod -aG docker $USER

    echo -e "${GREEN}✅ Docker 설치 완료${NC}"

else

    echo -e "${GREEN}✅ Docker 이미 설치됨: $(docker --version)${NC}"

fi



# Docker Compose 설치 확인

echo -e "${BLUE}[2/6]${NC} Docker Compose 확인 중..."

if ! command -v docker-compose &> /dev/null; then

    echo -e "${YELLOW}Docker Compose가 없습니다. 설치 중...${NC}"

    sudo curl -L "https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

    sudo chmod +x /usr/local/bin/docker-compose

    echo -e "${GREEN}✅ Docker Compose 설치 완료${NC}"

else

    echo -e "${GREEN}✅ Docker Compose 이미 설치됨: $(docker-compose --version)${NC}"

fi



# 방화벽 설정

echo -e "${BLUE}[3/6]${NC} 방화벽 설정 중..."

if command -v ufw &> /dev/null; then

    sudo ufw allow 5678/tcp comment "n8n web interface"

    echo -e "${GREEN}✅ 포트 5678 개방 완료${NC}"

else

    echo -e "${YELLOW}⚠️  UFW 없음. AWS Lightsail 콘솔에서 포트 5678 수동 개방 필요${NC}"

fi



# 기존 컨테이너 중지

echo -e "${BLUE}[4/6]${NC} 기존 컨테이너 확인..."

docker-compose down 2>/dev/null || true



# 컨테이너 시작

echo -e "${BLUE}[5/6]${NC} n8n 컨테이너 시작 중..."

docker-compose up -d



# 상태 확인

echo -e "${BLUE}[6/6]${NC} 서비스 상태 확인..."

sleep 5

docker-compose ps



echo ""

echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo -e "${GREEN}✅ 설치 완료!${NC}"

echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo ""

echo -e "${BLUE}접속 정보:${NC}"

echo -e "  ������ URL: ${YELLOW}http://43.203.181.195:5678${NC}"

echo -e "  ������ 사용자: ${YELLOW}admin${NC}"

echo -e "  ������ 비밀번호: ${YELLOW}ChangeThisPassword123!${NC}"

echo ""

echo -e "${BLUE}다음 단계:${NC}"

echo "  1. 웹 브라우저에서 위 URL 접속"

echo "  2. 로그인 후 워크플로우 가져오기"

echo "  3. PostgreSQL, SMTP 등 Credentials 설정"

echo "  4. 워크플로우 활성화"

echo ""

echo -e "${BLUE}유용한 명령어:${NC}"

echo "  docker-compose logs -f n8n    # 로그 확인"

echo "  docker-compose ps             # 상태 확인"

echo "  docker-compose restart        # 재시작"

echo "  docker-compose down           # 중지"

echo ""

