# Deployment Guide

Complete instructions for deploying the Intelligent Pipeline System to production environments.

## Local Development

### Prerequisites
- PostgreSQL 15+ with PostGIS 3.4+
- Python 3.9+
- Node.js 16+
- Mapbox account (free tier)

### Quick Setup

```bash
# Run automated setup
chmod +x quickstart.sh
./quickstart.sh        # macOS/Linux
# OR
quickstart.bat         # Windows
```

### Manual Setup

```bash
# 1. Database
createdb pipeline_gis
psql pipeline_gis < database_schema.sql

# 2. Backend
cd backend
python -m venv venv
source venv/bin/activate  # or venv\Scripts\activate on Windows
pip install -r requirements.txt
uvicorn main:app --reload

# 3. Frontend (new terminal)
cd frontend
npm install
# Edit .env with Mapbox token
npm run dev
```

---

## Docker Compose (Recommended)

### Quick Start

```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f backend

# Stop services
docker-compose down
```

### Services
- **PostgreSQL + PostGIS**: `localhost:5432`
- **FastAPI**: `localhost:8000`
- **Frontend**: Run locally with `npm run dev`

### Database in Docker

```bash
# Connect to database
psql -h localhost -U postgres -d pipeline_gis

# View tables
\dt
```

---

## AWS Deployment

### Architecture
```
ALB (Application Load Balancer)
├── ECS Task (FastAPI)
│   └── RDS PostgreSQL + PostGIS
└── CloudFront → S3 (React Frontend)
```

### Step 1: RDS PostgreSQL

1. **Create RDS Instance**:
   - Engine: PostgreSQL 15.x
   - Instance class: db.t3.micro (free tier eligible)
   - Storage: 20 GB (gp2)
   - Multi-AZ: No (dev/test)

2. **Install PostGIS**:
   ```sql
   CREATE EXTENSION postgis;
   CREATE EXTENSION postgis_topology;
   ```

3. **Load Schema**:
   ```bash
   psql -h <RDS_ENDPOINT> -U postgres -d postgres < database_schema.sql
   ```

### Step 2: ECS Fargate (FastAPI)

1. **Create ECR Repository**:
   ```bash
   aws ecr create-repository --repository-name pipeline-api --region us-east-1
   ```

2. **Build & Push Docker Image**:
   ```bash
   cd backend
   docker build -t pipeline-api .
   docker tag pipeline-api:latest <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/pipeline-api:latest
   docker push <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/pipeline-api:latest
   ```

3. **Create ECS Task Definition**:
   ```json
   {
     "family": "pipeline-api",
     "networkMode": "awsvpc",
     "requiresCompatibilities": ["FARGATE"],
     "cpu": "256",
     "memory": "512",
     "containerDefinitions": [
       {
         "name": "pipeline-api",
         "image": "<ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/pipeline-api:latest",
         "portMappings": [
           {
             "containerPort": 8000,
             "protocol": "tcp"
           }
         ],
         "environment": [
           {
             "name": "DATABASE_URL",
             "value": "postgresql+asyncpg://postgres:password@<RDS_ENDPOINT>:5432/pipeline_gis"
           }
         ],
         "logConfiguration": {
           "logDriver": "awslogs",
           "options": {
             "awslogs-group": "/ecs/pipeline-api",
             "awslogs-region": "us-east-1",
             "awslogs-stream-prefix": "ecs"
           }
         }
       }
     ]
   }
   ```

4. **Create ECS Service**:
   - Cluster: new or existing
   - Task definition: pipeline-api
   - Desired count: 2 (auto-scaling)
   - Load balancer: ALB on port 80/443

### Step 3: CloudFront + S3 (React)

1. **Build React App**:
   ```bash
   cd frontend
   npm run build
   ```

2. **Create S3 Bucket**:
   ```bash
   aws s3 mb s3://pipeline-ui --region us-east-1
   aws s3 sync dist/ s3://pipeline-ui --delete
   ```

3. **Create CloudFront Distribution**:
   - Origin: S3 bucket
   - Default root: `index.html`
   - Cache: Leverage browser cache
   - Compress: Yes

4. **Update Frontend .env**:
   ```env
   VITE_API_URL=https://api.example.com
   VITE_MAPBOX_TOKEN=your_token
   ```

5. **Redeploy Frontend**:
   ```bash
   npm run build
   aws s3 sync dist/ s3://pipeline-ui --delete
   ```

### Step 4: SSL/TLS (AWS Certificate Manager)

1. **Request Certificate**: ACM for `*.example.com`
2. **Attach to ALB**: Update listener to HTTPS
3. **CloudFront**: Use ACM certificate

### Step 5: Enable CORS

Update backend `main.py`:
```python
origins = [
    "https://dxxxxx.cloudfront.net",
    "https://api.example.com",
]
```

---

## Google Cloud Deployment

### Architecture
```
Cloud Load Balancer
├── Cloud Run (FastAPI)
├── Cloud SQL PostgreSQL + PostGIS
└── Cloud Storage + CDN (React)
```

### Step 1: Cloud SQL

```bash
gcloud sql instances create pipeline-db \
  --database-version=POSTGRES_15 \
  --tier=db-f1-micro \
  --region=us-central1

# Create database
gcloud sql databases create pipeline_gis --instance=pipeline-db

# Load schema
gcloud sql connect pipeline-db --user=postgres
# Then run: \i database_schema.sql

# Install PostGIS
gcloud sql connect pipeline-db
CREATE EXTENSION postgis;
```

### Step 2: Cloud Run (FastAPI)

```bash
# Build and push
gcloud builds submit backend --tag gcr.io/PROJECT_ID/pipeline-api

# Deploy
gcloud run deploy pipeline-api \
  --image gcr.io/PROJECT_ID/pipeline-api \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --set-env-vars DATABASE_URL=postgresql+asyncpg://postgres:pass@<CLOUD_SQL_IP>:5432/pipeline_gis \
  --memory 512Mi
```

### Step 3: Cloud Storage + CDN

```bash
# Create bucket
gsutil mb gs://pipeline-ui

# Upload React build
gsutil -m cp -r frontend/dist/* gs://pipeline-ui/

# Enable CDN
gcloud compute backend-buckets create pipeline-ui-backend \
  --gcs-uri-prefix=gs://pipeline-ui \
  --enable-cdn
```

---

## Heroku Deployment

### Backend (FastAPI)

1. **Create Procfile**:
   ```
   web: gunicorn main:app --worker-class uvicorn.workers.UvicornWorker --bind 0.0.0.0:$PORT
   ```

2. **Install Gunicorn**:
   ```bash
   pip install gunicorn
   pip freeze > backend/requirements.txt
   ```

3. **Deploy**:
   ```bash
   cd backend
   heroku create pipeline-api
   heroku addons:create heroku-postgresql:hobby-dev
   heroku config:set DATABASE_URL=postgresql+asyncpg://...
   git push heroku main
   ```

4. **Load Schema**:
   ```bash
   heroku pg:psql < database_schema.sql
   ```

### Frontend (Vercel)

```bash
cd frontend
npm install -g vercel
vercel --prod
```

Update `vercel.json`:
```json
{
  "env": {
    "VITE_API_URL": "https://pipeline-api.herokuapp.com"
  }
}
```

---

## DigitalOcean Deployment

### Step 1: App Platform

1. Create new app
2. Connect GitHub repo
3. Configure services:
   - **Backend**:
     - Build: `pip install -r requirements.txt`
     - Run: `uvicorn main:app --host 0.0.0.0 --port 8080`
   - **Database**: Managed PostgreSQL 15

4. Set env vars:
   ```
   DATABASE_URL=postgresql://user:pass@db-host:5432/pipeline_gis
   ```

### Step 2: Configure PostGIS

```bash
# SSH into Droplet
doctl compute ssh your-droplet

# Connect to database
psql $DATABASE_URL

# Enable PostGIS
CREATE EXTENSION postgis;
```

### Step 3: Load Sample Data

```bash
doctl compute ssh your-droplet
psql $DATABASE_URL < database_schema.sql
```

---

## Performance Optimization

### Database

```sql
-- Vacuum and analyze
VACUUM ANALYZE;

-- Check index usage
SELECT schemaname, tablename, indexname
FROM pg_indexes
WHERE tablename ~ 'pipelines';

-- Increase work_mem for large queries
SET work_mem = '256MB';
```

### Backend

1. **Enable Connection Pooling**:
   ```python
   from sqlalchemy.pool import QueuePool
   engine = create_async_engine(
       DATABASE_URL,
       poolclass=QueuePool,
       pool_size=20,
       max_overflow=40,
   )
   ```

2. **Add Redis Cache**:
   ```bash
   pip install redis aioredis
   ```

3. **Enable Compression**:
   ```python
   from fastapi.middleware.gzip import GZIPMiddleware
   app.add_middleware(GZIPMiddleware, minimum_size=1000)
   ```

### Frontend

1. **Code Splitting**:
   ```javascript
   const Map = lazy(() => import('./Map'));
   const PipelineList = lazy(() => import('./PipelineList'));
   ```

2. **Image Optimization**: Use Mapbox vector tiles

3. **CDN**: CloudFront, Cloudflare, or DigitalOcean CDN

---

## Monitoring & Logging

### Backend

```python
import logging
from pythonjsonlogger import jsonlogger

logger = logging.getLogger()
handler = logging.StreamHandler()
formatter = jsonlogger.JsonFormatter()
handler.setFormatter(formatter)
logger.addHandler(handler)
```

### Services

- **AWS**: CloudWatch
- **GCP**: Cloud Logging
- **Heroku**: Papertrail
- **DigitalOcean**: Sentry

---

## Continuous Integration/Deployment

### GitHub Actions

Create `.github/workflows/deploy.yml`:
```yaml
name: Deploy

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Build and push
        run: |
          docker build -t pipeline-api:${{ github.sha }} backend/
          docker tag pipeline-api:${{ github.sha }} pipeline-api:latest
      - name: Deploy to ECS
        run: aws ecs update-service --cluster pipeline --service api --force-new-deployment
```

---

## Backup & Recovery

### PostgreSQL

```bash
# Backup
pg_dump pipeline_gis > backup.sql

# Restore
createdb pipeline_gis_restore
psql pipeline_gis_restore < backup.sql

# AWS RDS Snapshot
aws rds create-db-snapshot --db-instance-identifier pipeline-db --db-snapshot-identifier backup-$(date +%s)
```

---

## Troubleshooting

### Database Connection
```bash
# Test connection
psql -h <host> -U postgres -d pipeline_gis -c "SELECT PostGIS_Version();"
```

### API Health
```bash
curl http://localhost:8000/health
```

### Geographic Queries
```sql
-- Verify indexes
EXPLAIN ANALYZE SELECT * FROM pipelines_routes WHERE ST_DWithin(geom, ST_Point(-96, 32, 4326), 0.1);
```

---

For production support, consult cloud provider documentation and consider hiring DevOps resources.
