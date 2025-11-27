#StreamSync Lite 

StreamSync Lite is an end-to-end mobile learning platform featuring video streaming, resume playback, push notifications, offline caching, and real-time progress sync.
This repository contains both the Flutter mobile app and the Node.js backend deployed on AWS EC2 + RDS.

📁 Project Structure
StreamSync-Lite/
│
├── frontend/                     # Flutter mobile app
│   ├── lib/
│   ├── android/ ios/
│   └── pubspec.yaml
│
├── backend/                      # Node.js + TypeORM REST API
│   ├── src/
│   │   ├── main.ts               # All API routes
│   │   ├── data-source.ts        # DB connection
│   │   └── entities/             # ORM models
│   ├── package.json
│   ├── Dockerfile
│   ├── tsconfig.json
│   └── .env.example
│
└── README.md

🖼 Architecture Diagram (Mermaid)

The diagram automatically renders on GitHub.

flowchart LR
    A[Flutter App] -->|API Calls| B[Node.js Backend - Express + TypeORM]
    B -->|Queries| C[(AWS RDS MySQL)]
    B -->|Push Requests| D[Firebase Cloud Messaging]
    D -->|Push Notifications| A

    A -->|Video Streaming| E[Video CDN / YouTube / Custom Storage]

    subgraph Mobile Features
        A1[Login / Register]
        A2[Video Feed]
        A3[Player + Resume]
        A4[Offline Cache]
        A5[Notifications]
    end

🌐 Live Backend URL

Replace with your actual deployment URL:

http://your-ec2-public-ip:3000


Health check:

GET /health

📸 Demo Video & Screenshots
📽 Demo Video (2–4 minutes)

Replace this with your own:

https://youtu.be/demo-video-link

📷 App Screenshots
![Login](docs/login.png)
![Home Feed](docs/feed.png)
![Video Player](docs/player.png)
![Notifications](docs/notifications.png)

🔐 Environment Configuration

All env variables are placed inside backend/.env.example


Include .env.example:

DB_HOST=
DB_PORT=
DB_USER=
DB_PASSWORD=
DB_NAME=


🐳 Backend Dockerfile
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .

RUN npm run build

EXPOSE 3000

CMD ["node", "dist/main.js"]

🛠 Backend Setup – AWS EC2 Deployment
1. SSH Into EC2
ssh -i key.pem ubuntu@your-ec2-ip

2. Install Node, Git, Build Tools
sudo apt update
sudo apt install -y nodejs npm git

3. Clone Repository
git clone https://github.com/you/StreamSync-Lite.git
cd StreamSync-Lite/backend

4. Install Dependencies
npm install

5. Configure Environment Variables
nano .env


Paste your DB + FCM + JWT settings.

6. Build & Run
npm run build
node dist/main.js

7. Run Backend in Background (PM2)
sudo npm install -g pm2
pm2 start dist/main.js --name streamsync
pm2 save
pm2 startup

🛢 AWS RDS Setup

Launch MySQL RDS instance

Add inbound rule:

MySQL/Aurora – port 3306 – allow EC2 security group


Initialize DB:

mysql -h your-rds-endpoint -u admin -p
CREATE DATABASE streamsync;


Tables auto-generate from TypeORM.

📱 Flutter App Setup
1. Update ApiClient Base URL

lib/services/api_client.dart:

static const baseUrl = "http://your-ec2-ip:3000";

2. Install Packages
flutter pub get

3. Build APK / iOS
flutter build apk
# OR
flutter build ios

🔔 Push Notification Setup (FCM)

Add Firebase to Flutter app

Add google-services.json

Add FCM Server Key to .env

Backend stores tokens in fcm_tokens table

User can trigger “Test Push” from profile screen

Test endpoint:

POST /notifications/send-test

🧪 Core API Endpoints
Auth
POST /auth/register
POST /auth/login

Videos
GET /videos
POST /videos/progress

Notifications
GET /notifications/:userId
POST /notifications/send-test
DELETE /notifications/:id

Health
GET /health

📦 Tech Stack
Frontend

Flutter

Provider / Stateful Architecture

Video Player

Offline download

FCM notifications

Backend

Node.js

Express

TypeORM

MySQL (AWS RDS)

Firebase Admin SDK

PM2 (background runtime on EC2)

📜 Assignment Checklist

✔ /frontend + /backend included
✔ README with architecture diagram
✔ .env.example
✔ Dockerfile
✔ AWS EC2 deployment
✔ AWS RDS setup
✔ Working push notifications
✔ Video demo link
✔ Clean documentation

📄 License

MIT or any license you prefe
