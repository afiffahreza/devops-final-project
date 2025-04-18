cd ../../
mvn clean package -DskipTests
docker compose -f devopspipeline/owaspzap/zap-compose.yml up --build  --abort-on-container-exit --exit-code-from zap