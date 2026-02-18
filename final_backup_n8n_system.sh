
#!/bin/bash



echo "======================================================================"

echo "������ n8n 유지보수 알람 시스템 최종 백업 (HTML 이메일 버전)"

echo "======================================================================"



# 백업 디렉토리 생성

BACKUP_DATE=$(date +%Y%m%d_%H%M%S)

BACKUP_DIR="/home/ubuntu/backups/n8n-maintenance-final-${BACKUP_DATE}"

mkdir -p "${BACKUP_DIR}"



echo ""

echo "������ 백업 디렉토리: ${BACKUP_DIR}"

echo ""



# 1. n8n 워크플로우 백업

echo "1️⃣ n8n 워크플로우 백업 중..."

docker exec n8n tar czf - /home/node/.n8n > "${BACKUP_DIR}/n8n_workflows.tar.gz" 2>/dev/null

echo "   ✅ n8n 워크플로우 백업 완료"



# 2. PostgreSQL 데이터베이스 백업

echo ""

echo "2️⃣ PostgreSQL 데이터베이스 백업 중..."

docker exec n8n-postgres pg_dump -U n8n maintenance_db > "${BACKUP_DIR}/maintenance_db_backup.sql"

echo "   ✅ PostgreSQL 백업 완료"



# 3. Docker Compose 설정 백업

echo ""

echo "3️⃣ Docker Compose 설정 백업 중..."

cp ~/n8n-renewal-system/docker-compose.yml "${BACKUP_DIR}/" 2>/dev/null || echo "   ⚠️ docker-compose.yml not found"



# 4. 데이터 파일 백업

echo ""

echo "4️⃣ 데이터 파일 백업 중..."

if [ -f ~/data_4.xlsx ]; then

    cp ~/data_4.xlsx "${BACKUP_DIR}/"

    echo "   ✅ data_4.xlsx 백업 완료"

fi



# 5. 스크립트 파일 백업

echo ""

echo "5️⃣ 스크립트 파일 백업 중..."

cp ~/*.py "${BACKUP_DIR}/" 2>/dev/null

cp ~/*.sh "${BACKUP_DIR}/" 2>/dev/null



# 6. 시스템 정보 및 설정 저장

echo ""

echo "6️⃣ 시스템 정보 저장 중..."

cat > "${BACKUP_DIR}/SYSTEM_INFO.txt" <<INFO

====================================================================

n8n 유지보수 알람 시스템 최종 백업

====================================================================

백업 일시: $(date '+%Y-%m-%d %H:%M:%S')

백업 위치: ${BACKUP_DIR}

시스템 버전: HTML 이메일 형식 + 10일 단위/매일 알림 + 갱신 확정 기능



====================================================================

주요 기능

====================================================================

✅ PostgreSQL 데이터베이스 (268개 계약)

✅ n8n 워크플로우 (계약갱신 자동알림)

✅ Gmail SMTP 연동

✅ HTML 이메일 형식 (깔끔한 레이아웃)

✅ 스마트 알림 규칙:

   - D-90 ~ D-30: 10일 단위 (D-90, D-80, D-70, D-60, D-50, D-40, D-30)

   - D-30 ~ D-0: 매일 알림

✅ 갱신 확정 기능 (알림 자동 중지)

✅ 평일 오전 8시 자동 실행 (설정 대기 중)



====================================================================

Docker 컨테이너 상태

====================================================================

$(docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}")



====================================================================

PostgreSQL 데이터베이스 통계

====================================================================

$(docker exec n8n-postgres psql -U n8n -d maintenance_db -c "

SELECT 

    '총 계약 수' as metric,

    COUNT(*) as count

FROM contracts

UNION ALL

SELECT 

    '활성 계약',

    COUNT(*)

FROM contracts

WHERE status = 'active'

UNION ALL

SELECT 

    '90일 이내 만료',

    COUNT(*)

FROM contracts

WHERE status = 'active'

  AND end_date::DATE >= CURRENT_DATE::DATE

  AND end_date::DATE <= (CURRENT_DATE::DATE + INTERVAL '90 days')

UNION ALL

SELECT 

    '갱신 확정',

    COUNT(*)

FROM contracts

WHERE renewal_status = 'confirmed'

UNION ALL

SELECT 

    '총 월 계약 금액 (원)',

    CAST(SUM(monthly_amount) as BIGINT)

FROM contracts

WHERE status = 'active';

" 2>/dev/null)



====================================================================

테이블 구조 (contracts)

====================================================================

$(docker exec n8n-postgres psql -U n8n -d maintenance_db -c "\d contracts" 2>/dev/null)



====================================================================

알림 단계별 분포 (오늘 기준)

====================================================================

$(docker exec n8n-postgres psql -U n8n -d maintenance_db -c "

SELECT 

    CASE

        WHEN (end_date::DATE - CURRENT_DATE::DATE) % 10 = 0 AND (end_date::DATE - CURRENT_DATE::DATE) BETWEEN 30 AND 90 THEN 'D-' || (end_date::DATE - CURRENT_DATE::DATE)::TEXT || ' (10일 단위)'

        WHEN (end_date::DATE - CURRENT_DATE::DATE) BETWEEN 0 AND 30 THEN 'D-' || (end_date::DATE - CURRENT_DATE::DATE)::TEXT || ' (매일)'

        ELSE '제외 (10일 단위 아님)'

    END as alert_type,

    COUNT(*) as count

FROM contracts

WHERE status = 'active'

  AND end_date::DATE >= CURRENT_DATE::DATE

  AND end_date::DATE <= (CURRENT_DATE::DATE + INTERVAL '90 days')

  AND (renewal_status IS NULL OR renewal_status != 'confirmed')

  AND (notification_enabled IS NULL OR notification_enabled = true)

GROUP BY alert_type

ORDER BY alert_type;

" 2>/dev/null)



====================================================================

담당자별 계약 현황

====================================================================

$(docker exec n8n-postgres psql -U n8n -d maintenance_db -c "

SELECT 

    sales_rep_name,

    COUNT(*) as total_contracts,

    TO_CHAR(SUM(monthly_amount), 'FM999,999,999') || '원' as total_amount,

    COUNT(*) FILTER (

        WHERE end_date::DATE >= CURRENT_DATE::DATE

          AND end_date::DATE <= (CURRENT_DATE::DATE + INTERVAL '90 days')

    ) as alerts_90days,

    COUNT(*) FILTER (

        WHERE renewal_status = 'confirmed'

    ) as confirmed

FROM contracts

WHERE status = 'active'

GROUP BY sales_rep_name

ORDER BY total_amount DESC

LIMIT 10;

" 2>/dev/null)



====================================================================

다음 작업 (남은 단계)

====================================================================

⏸️ 미완료:

- [ ] data_4.xlsx에 담당자별 이메일 추가

- [ ] PostgreSQL 이메일 필드 업데이트

- [ ] 스케줄 활성화 (평일 오전 8시)

- [ ] (선택) Slack 알림 추가

- [ ] (선택) SMS 알림 추가



====================================================================

갱신 확정 방법

====================================================================

# 특정 계약 갱신 확정

docker exec n8n-postgres psql -U n8n -d maintenance_db -c "

UPDATE contracts

SET 

    renewal_status = 'confirmed',

    notification_enabled = false,

    renewal_confirmed_at = CURRENT_TIMESTAMP,

    renewal_confirmed_by = '담당자명'

WHERE contract_number = 'M158';

"



# 갱신 확정 상태 확인

docker exec n8n-postgres psql -U n8n -d maintenance_db -c "

SELECT 

    contract_number,

    customer_name,

    renewal_status,

    notification_enabled,

    renewal_confirmed_at,

    renewal_confirmed_by

FROM contracts

WHERE renewal_status = 'confirmed'

ORDER BY renewal_confirmed_at DESC;

"



====================================================================

복구 방법

====================================================================

1. 백업 압축 해제:

   tar xzf n8n-maintenance-final-${BACKUP_DATE}.tar.gz



2. PostgreSQL 복구:

   docker exec -i n8n-postgres psql -U n8n -d maintenance_db < maintenance_db_backup.sql



3. n8n 워크플로우 복구:

   docker exec -i n8n tar xzf - -C / < n8n_workflows.tar.gz

   docker-compose restart n8n



4. 시스템 확인:

   docker ps

   docker exec n8n-postgres psql -U n8n -d maintenance_db -c "SELECT COUNT(*) FROM contracts;"



====================================================================

n8n 접속 정보

====================================================================

URL: http://43.203.181.195:5678

워크플로우: 계약갱신 자동알림 시스템



====================================================================

백업 완료!

====================================================================

INFO



echo "   ✅ 시스템 정보 저장 완료"



# 7. 전체 백업 압축

echo ""

echo "7️⃣ 전체 백업 압축 중..."

cd /home/ubuntu/backups

tar czf "n8n-maintenance-final-${BACKUP_DATE}.tar.gz" "n8n-maintenance-final-${BACKUP_DATE}"

BACKUP_SIZE=$(du -h "n8n-maintenance-final-${BACKUP_DATE}.tar.gz" | cut -f1)

echo "   ✅ 백업 압축 완료 (크기: ${BACKUP_SIZE})"



# 8. 백업 요약

echo ""

echo "======================================================================"

echo "✅ 최종 백업 완료!"

echo "======================================================================"

echo ""

echo "������ 백업 파일:"

echo "   로컬: /home/ubuntu/backups/n8n-maintenance-final-${BACKUP_DATE}.tar.gz"

echo "   크기: ${BACKUP_SIZE}"

echo ""

echo "������ 백업 내용:"

ls -lh "${BACKUP_DIR}" | tail -n +2 | awk '{printf "   - %-40s %10s\n", $9, $5}'

echo ""

echo "======================================================================"

echo "������ 시스템 상태 (최종)"

echo "======================================================================"

docker exec n8n-postgres psql -U n8n -d maintenance_db -c "

SELECT 

    '총 계약 수' as 항목,

    COUNT(*) as 값

FROM contracts

UNION ALL

SELECT 

    '활성 계약',

    COUNT(*)

FROM contracts

WHERE status = 'active'

UNION ALL

SELECT 

    '90일 이내 만료',

    COUNT(*)

FROM contracts

WHERE status = 'active'

  AND end_date::DATE >= CURRENT_DATE::DATE

  AND end_date::DATE <= (CURRENT_DATE::DATE + INTERVAL '90 days')

UNION ALL

SELECT 

    '오늘 발송 대상',

    COUNT(*)

FROM contracts

WHERE status = 'active'

  AND end_date::DATE >= CURRENT_DATE::DATE

  AND end_date::DATE <= (CURRENT_DATE::DATE + INTERVAL '90 days')

  AND (

    ((end_date::DATE - CURRENT_DATE::DATE) BETWEEN 0 AND 30)

    OR

    ((end_date::DATE - CURRENT_DATE::DATE) % 10 = 0 AND (end_date::DATE - CURRENT_DATE::DATE) BETWEEN 30 AND 90)

  )

  AND (renewal_status IS NULL OR renewal_status != 'confirmed')

  AND (notification_enabled IS NULL OR notification_enabled = true)

UNION ALL

SELECT 

    '총 월 계약 금액 (원)',

    CAST(SUM(monthly_amount) as BIGINT)

FROM contracts

WHERE status = 'active';

" | sed 's/^/   /'



echo ""

echo "======================================================================"

echo "������ 백업 완료! 다음 작업을 위한 준비가 끝났습니다."

echo "======================================================================"

echo ""

echo "다음 작업:"

echo "1️⃣ data_4.xlsx에 담당자 이메일 추가"

echo "2️⃣ PostgreSQL 이메일 업데이트"

echo "3️⃣ 스케줄 활성화 (평일 오전 8시)"

echo ""



