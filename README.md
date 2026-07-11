# Socialdev App

## High-Level Architecture (Microservices + Event-Driven)

ระบบออกแบบเป็น **microservices** แยกตาม domain และสื่อสารกันแบบ async ผ่าน **Event Bus (Kafka / Redpanda)** สำหรับงานที่ไม่ต้องรอผลลัพธ์ทันที เช่น การแจ้งเตือน, การสร้างห้องแชทอัตโนมัติ และ analytics ระบบแชทใช้ **WebSocket** สำหรับ real-time messaging

```mermaid
flowchart TD
    subgraph FRONTEND["🖥️ FRONTEND (Flutter Client)"]
        direction LR
        UI1["Welcome / Login / Register"]
        UI2["Student Dashboard\nMap · Activities · Profile"]
        UI3["Teacher Dashboard\nActivities · Home · Profile"]
        UI4["Organization Dashboard\nMap · Home · Profile"]
        STATE["State: Provider\nAuthService · ActivityService\nChatService · ProblemService"]
        NET["Network: HTTP · WebSocket · Auth0\nUI: google_maps · image_picker · geolocator"]
    end

    AUTH0["🔐 Auth0\n(Google OIDC)"]

    subgraph INTERNET["🌐 Internet"]
        CF["Cloudflare Tunnel\nsocialdev.parameedev.online\n(namespace: dev-paramee)"]
    end

    subgraph K8S["☸️ Kubernetes Cluster (namespace: socialdev)"]
        KONG["Kong API Gateway\nkong-proxy.kong.svc.cluster.local:80"]

        subgraph APPS["Application Pods (Go Fiber v3)"]
            SVC_AUTH["Auth :8080\nDeployment + Service"]
            SVC_IMG["Image :8081\nDeployment + Service"]
            SVC_PROB["Problem :8083\nDeployment + Service"]
            SVC_ACT["Activity :8084\nDeployment + Service"]
            SVC_CHAT["Chat :8085\nDeployment + Service\nWebSocket + REST"]
            SVC_NOTIF["Notification :8086\nDeployment + Service"]
            SVC_ANALYTICS["Analytics :8087\nDeployment + Service"]
        end

        subgraph INFRA_K8S["Infrastructure (in-cluster)"]
            REDPANDA["Redpanda\n(Kafka API)\nnamespace: socialdev"]
        end

        subgraph CONFIG["Config & Secrets"]
            CM["ConfigMap: app-config\nDB_HOST · KAFKA_BROKERS\nMINIO_ENDPOINT · AUTH0_DOMAIN"]
            SEC["Secrets\ndb-socialdev · jwt-secret\nminio-secret · firebase-credentials"]
        end
    end

    subgraph EXTERNAL["🖥️ External Servers (bare-metal)"]
        PG["PostgreSQL\n10.194.1.43:5432\nsocialdev_auth/problem/activity\nchat/image/analytics"]
        MINIO["MinIO (S3)\n10.194.1.44:9000\nbucket: socialdev"]
    end

    FRONTEND -->|"HTTPS / WSS"| CF
    FRONTEND -->|"OAuth2"| AUTH0
    CF -->|"proxy"| KONG
    KONG -->|"route by path"| APPS

    AUTH0 -->|"JWT verify"| SVC_AUTH

    SVC_AUTH & SVC_PROB & SVC_ACT & SVC_CHAT & SVC_ANALYTICS & SVC_NOTIF -->|"TCP 5432"| PG
    SVC_IMG -->|"TCP 9000"| MINIO
    SVC_IMG -->|"TCP 5432"| PG

    APPS -->|"publish events\nkafka-0.kafka-headless.kafka.svc:9092"| REDPANDA
    REDPANDA -->|"consume events"| SVC_NOTIF
    REDPANDA -->|"consume events"| SVC_ANALYTICS

    CONFIG -.->|"injected via env"| APPS
```

---

## 1. Request Flow (Internet → K8s)

คำอธิบาย: request จาก Flutter ไปถึง backend pods ผ่านอะไรบ้าง

```mermaid
flowchart LR
    APP["📱 Flutter App"] -->|"HTTPS/WSS\nsocialdev.parameedev.online"| CF

    subgraph TUNNEL["Cloudflare (namespace: dev-paramee)"]
        CF["cloudflared pod\nTunnel ID: 17b067d7"]
    end

    CF -->|"http://kong-proxy.kong\n.svc.cluster.local:80"| KONG

    subgraph K8S["☸️ K8s Cluster (namespace: socialdev)"]
        KONG["Kong API Gateway"] -->|"/auth/*"| P1["auth :8080"]
        KONG -->|"/api/images/*"| P2["image :8081"]
        KONG -->|"/api/problems/*"| P3["problem :8083"]
        KONG -->|"/api/activities/*"| P4["activity :8084"]
        KONG -->|"/api/chat/* · /ws"| P5["chat :8085"]
    end
```

---

## 2. Authentication Flow

คำอธิบาย: การ login 2 แบบ — Local (email/password) และ Google OAuth ผ่าน Auth0

```mermaid
flowchart TD
    USER["👤 User"] --> CHOICE{เลือก login}

    CHOICE -->|"email + password"| LOCAL["POST /auth/login\nAuth Service :8080"]
    LOCAL --> BCRYPT["bcrypt verify\npassword"]
    BCRYPT --> SIGN["Sign JWT\n(jwt-secret from Secret)"]
    SIGN --> TOKEN["JWT → Flutter"]

    CHOICE -->|"Login with Google"| APPAUTH["flutter_appauth\nAuth0 PKCE flow"]
    APPAUTH --> AUTH0["🔐 Auth0\ndev-p6m40iaxhz0i543y.us.auth0.com"]
    AUTH0 --> CALLBACK["Redirect\ncom.socialdev.app://login-callback"]
    CALLBACK --> GOAUTH["POST /auth/google\nAuth Service :8080"]
    GOAUTH --> UPSERT["Upsert user\nใน PostgreSQL"]
    UPSERT --> SIGN

    TOKEN --> STORE["SharedPreferences\nเก็บ JWT ใน device"]
    STORE --> API["ใช้ JWT ใน\nAuthorization header"]
```

---

## 3. Kubernetes Internal (Pods, Config, Secrets)

คำอธิบาย: ภายใน cluster — pods อ่าน config และ secret อย่างไร, init container ทำงานอะไร

```mermaid
flowchart TD
    subgraph NS["namespace: socialdev"]
        subgraph CM_SEC["Config & Secrets"]
            CM["ConfigMap: app-config\nDB_HOST: 10.194.1.43\nDB_PORT: 5432\nKAFKA_BROKERS: kafka-0.kafka-headless\nMINIO_ENDPOINT: 10.194.1.44:9000\nAUTH0_DOMAIN: dev-p6m40iaxhz0i543y"]
            SEC1["Secret: db-socialdev\nDB_PASSWORD"]
            SEC2["Secret: jwt-secret\nJWT_SECRET"]
            SEC3["Secret: minio-secret\nMINIO_ACCESS_KEY · MINIO_SECRET_KEY"]
            SEC4["Secret: firebase-credentials\ncredentials.json (FCM)"]
        end

        subgraph POD["ทุก App Pod (ยกเว้น notification)"]
            INIT["initContainer: wait-postgres\nnc -z 10.194.1.43 5432\n(รอ DB พร้อมก่อน start)"]
            INIT --> MAIN["main container\nGo Fiber v3\nreadinessProbe: GET /health"]
        end

        subgraph POD_NOTIF["Notification Pod (พิเศษ)"]
            VOL1["volumeMount: /etc/notification/config.yaml\n(ConfigMap: notification-config)"]
            VOL2["volumeMount: /etc/firebase/credentials.json\n(Secret: firebase-credentials)"]
            NOTIF_MAIN["notification-service\nGo · consume Kafka events"]
        end

        CM & SEC1 & SEC2 -.->|"env injection"| MAIN
        SEC3 -.->|"env injection (image pod only)"| MAIN
        VOL1 & VOL2 --> NOTIF_MAIN
    end
```

---

## 4. Data Store Connections

คำอธิบาย: แต่ละ service เชื่อมกับ database ใด — ใช้ database-per-service pattern

```mermaid
flowchart LR
    subgraph PODS["Pods (in-cluster)"]
        A["auth :8080"]
        I["image :8081"]
        PR["problem :8083"]
        AC["activity :8084"]
        CH["chat :8085"]
        NO["notification :8086"]
        AN["analytics :8087"]
    end

    subgraph PG["PostgreSQL 10.194.1.43:5432"]
        DB1[("socialdev_auth")]
        DB2[("socialdev_image")]
        DB3[("socialdev_problem\n+ PostGIS")]
        DB4[("socialdev_activity")]
        DB5[("socialdev_chat")]
        DB6[("socialdev_analytics\nevent_log · event_counts")]
    end

    subgraph MINIO_BOX["MinIO 10.194.1.44:9000"]
        BUCKET["bucket: socialdev\n(รูปภาพทุกประเภท)"]
    end

    A --> DB1
    I --> DB2
    I --> BUCKET
    PR --> DB3
    AC --> DB4
    CH --> DB5
    AN --> DB6
    NO --> DB1
```

---

## 5. Event Bus Flow (Redpanda / Kafka)

คำอธิบาย: ระบบ async — producer publish event แล้ว consumer หยิบไปทำงาน

```mermaid
flowchart LR
    subgraph PRODUCERS["📤 Producers"]
        A["Auth Service"]
        PR["Problem Service"]
        AC["Activity Service"]
        CH["Chat Service"]
        IM["Image Service"]
    end

    subgraph BUS["📨 Redpanda\nkafka-0.kafka-headless\n.kafka.svc.cluster.local:9092"]
        T1["user.registered"]
        T2["problem.created\nproblem.status.changed"]
        T3["activity.created\nactivity.joined\nsubmission.reviewed"]
        T4["chat.message.sent\nchat.room.created"]
        T5["image.uploaded"]
    end

    subgraph CONSUMERS["📥 Consumers"]
        NO["Notification :8086\nFCM push / Email"]
        AN["Analytics :8087\nเก็บสถิติ event_log"]
    end

    A -->|publish| T1
    PR -->|publish| T2
    AC -->|publish| T3
    CH -->|publish| T4
    IM -->|publish| T5

    T1 & T2 & T3 & T4 -->|consume| NO
    T1 & T2 & T3 & T4 & T5 -->|consume| AN
```

---

## 6. Real-time Chat Flow (WebSocket)

คำอธิบาย: การส่งข้อความ real-time ผ่าน WebSocket + fallback REST

```mermaid
sequenceDiagram
    participant C as Flutter Client
    participant WS as Chat Service :8085
    participant DB as PostgreSQL (socialdev_chat)
    participant KB as Redpanda (Kafka)
    participant N as Notification :8086

    C->>WS: ws://host/ws?token=JWT
    WS-->>C: {"type":"connected","user_id":"3"}

    C->>WS: send_message {to_user_id, content}
    WS->>DB: findOrCreateRoom(sender, receiver)
    WS->>DB: INSERT message
    WS->>KB: publish chat.message.sent
    WS-->>C: new_message → UserA
    WS-->>C: new_message → UserB (ถ้า online)

    KB->>N: consume chat.message.sent
    N-->>C: FCM push (ถ้า UserB offline)

    Note over C,WS: Fallback: ถ้า WS ไม่พร้อม → REST POST /api/chat/messages
```

---

## 7. ระบบนักเรียน (Student Flow)

คำอธิบาย: สิ่งที่นักเรียนทำได้ทั้งหมดในระบบ ตั้งแต่ login จนถึง submit งานและแชทกับครู

```mermaid
flowchart TD
    LOGIN["🎓 Login as Student"] --> HOME["StudentScreen\n3 Tabs"]

    HOME --> TAB0["Tab 0: แผนที่ 🗺️\nMapHomeScreen"]
    HOME --> TAB1["Tab 1: กิจกรรม 📋"]
    HOME --> TAB2["Tab 2: โปรไฟล์ 👤"]

    %% Map Tab
    TAB0 --> MAP_VIEW["Google Maps\nแสดง markers ปัญหาชุมชน"]
    MAP_VIEW --> MAP_CLICK["กด marker\n→ ProblemDetailScreen\nดูรายละเอียดปัญหา"]
    MAP_VIEW --> ADD_PROB["กด + เพิ่มปัญหา\n→ AddProblemSheet\nกรอก title/desc/รูป/location\n→ POST /api/problems"]

    %% Activity Tab
    TAB1 --> ACT_MENU{เมนูกิจกรรม}
    ACT_MENU --> SCHOOL_ACT["SchoolActivitiesScreen\nดูกิจกรรมโรงเรียนทั้งหมด\nGET /api/activities"]
    ACT_MENU --> MY_REG["MyRegistrationsScreen\nกิจกรรมที่ลงทะเบียนแล้ว\nGET /api/activities/my-registrations"]

    %% School Activities flow
    SCHOOL_ACT --> ACT_DETAIL["ActivityDetailScreen\nดูรายละเอียด + แผนที่สถานที่\nชื่อครูผู้ดูแล + เบอร์ติดต่อ"]
    ACT_DETAIL --> REG_BTN["กด ลงทะเบียน\nPOST /api/activities/:id/register"]
    REG_BTN --> REG_OK["✅ ลงทะเบียนสำเร็จ\nEvent: activity.joined → Notification ครู"]

    %% My Registrations flow
    MY_REG --> REG_DETAIL["ดูรายละเอียดกิจกรรม\n+ แผนที่สถานที่จริง\n+ สถานะการส่งงาน"]
    REG_DETAIL --> UNREG["ถอนการลงทะเบียน\nDELETE /api/activities/registrations/:regId"]
    REG_DETAIL --> SUBMIT["ส่งงาน 📎\nPOST /registrations/:regId/submit\nแนบ text + รูป/ไฟล์"]
    REG_DETAIL --> CHAT_BTN["แชทกับครู 💬\n→ ChatRoomScreen"]

    SUBMIT --> SUBMIT_OK["✅ ส่งงานสำเร็จ\nสถานะ: pending → รอครูตรวจ"]

    %% Chat flow
    CHAT_BTN --> WS_CONN["WebSocket\nws://host:8085/ws?token=JWT\nAuto-reconnect 3s · Ping 30s"]
    WS_CONN --> SEND_MSG["ส่งข้อความ / รูปภาพ\n→ Image Service :8081\n→ chat message + image_id"]
    WS_CONN --> RECV_MSG["รับข้อความ real-time\nnew_message event"]

    %% Profile Tab
    TAB2 --> PROFILE["ดูโปรไฟล์\nชื่อ · อีเมล · avatar\nGET /user/profile"]
    PROFILE --> LOGOUT["Logout\nลบ JWT จาก SharedPreferences"]
```

---

## 8. ระบบครู (Teacher Flow)

คำอธิบาย: สิ่งที่ครูทำได้ทั้งหมด ตั้งแต่สร้างกิจกรรม ตรวจงาน จนถึงแชทกับนักเรียน

```mermaid
flowchart TD
    LOGIN["👩‍🏫 Login as Teacher"] --> HOME["TeacherScreen\n3 Tabs"]

    HOME --> TAB0["Tab 0: กิจกรรม 📋\nSchoolActivitiesScreen"]
    HOME --> TAB1["Tab 1: หน้าหลัก 🏠"]
    HOME --> TAB2["Tab 2: โปรไฟล์ 👤"]

    %% Tab 0 - Browse activities
    TAB0 --> BROWSE["ดูรายการกิจกรรมทั้งหมด\nGET /api/activities"]
    BROWSE --> ACT_D["ActivityDetailScreen\nดูรายละเอียด + แผนที่"]

    %% Tab 1 - Home quick menus
    TAB1 --> BANNER["Banner carousel\nข่าวประกาศ"]
    TAB1 --> QMENU{Quick Menu}
    QMENU --> ADD_ACT["➕ เพิ่มกิจกรรม\n→ AddActivityScreen"]
    QMENU --> REVIEW["📝 ตรวจงาน\n→ ReviewWorksScreen"]
    QMENU --> CHAT["💬 แชท\n→ TicketListScreen"]

    %% Add Activity flow
    ADD_ACT --> ACT_FORM["กรอกฟอร์มกิจกรรม\nชื่อ · รายละเอียด · สถานที่\nวัน-เวลาเริ่ม/สิ้นสุด · จำนวนรับ\nครูผู้ดูแล + เบอร์ติดต่อ"]
    ACT_FORM --> PIN_MAP["ปักหมุดแผนที่ 📍\nเลือก lat/lng สถานที่จัดกิจกรรม"]
    ACT_FORM --> UPLOAD_IMG["อัพโหลดรูปกิจกรรม 🖼️\nPOST /api/images (Image :8081)\n→ ได้ image_id"]
    ACT_FORM --> VISIBILITY["ตั้งค่า Visibility\npublic / private\nเลือกโรงเรียน"]
    PIN_MAP & UPLOAD_IMG & VISIBILITY --> SUBMIT_ACT["POST /api/activities\nสร้างกิจกรรม"]
    SUBMIT_ACT --> ACT_OK["✅ สร้างสำเร็จ\nEvent: activity.created\n→ Notification นักเรียน"]

    ACT_FORM --> EDIT_MODE["Edit Mode\nแก้ไขกิจกรรมที่มีอยู่"]

    %% Review Works flow
    REVIEW --> MY_ACTS["ดูกิจกรรมที่ครูสร้าง\nGET /api/activities/my-submissions"]
    MY_ACTS --> SUB_LIST["เลือกกิจกรรม\n→ ดูรายการ submissions\nของนักเรียนทุกคน"]
    SUB_LIST --> SUB_DETAIL["ดูรายละเอียดงาน\nเนื้อหา · ไฟล์แนบ · รูปภาพ\nชื่อนักเรียน · วันที่ส่ง"]
    SUB_DETAIL --> GRADE["ให้คะแนน + feedback\nPUT /submissions/:subId/review\nscore · status: passed/failed"]
    GRADE --> GRADE_OK["✅ ตรวจเสร็จ\nEvent: submission.reviewed\n→ Notification นักเรียน\n→ Chat feedback อัตโนมัติ"]

    %% Chat flow
    CHAT --> TICKET_LIST["TicketListScreen\nรายการห้องแชทกับนักเรียน\nGET /api/chat/rooms"]
    TICKET_LIST --> CHAT_ROOM["ChatRoomScreen\nGET /api/chat/rooms/:id/messages"]
    CHAT_ROOM --> WS_CONN["WebSocket\nws://host:8085/ws?token=JWT\nAuto-reconnect 3s · Ping 30s"]
    WS_CONN --> SEND["ส่งข้อความ / รูปภาพ"]
    WS_CONN --> RECV["รับข้อความ real-time"]

    %% Profile Tab
    TAB2 --> PROFILE["ดูโปรไฟล์\nGET /user/profile"]
    PROFILE --> EDIT_PROF["แก้ไขโปรไฟล์\nPUT /user/profile"]
    PROFILE --> LOGOUT["Logout"]
```

---

## 9. ระบบหน่วยงาน (Organization Flow)

คำอธิบาย: สิ่งที่หน่วยงานทำได้ — เน้นดูแผนที่ปัญหาชุมชนและจัดการกิจกรรม

```mermaid
flowchart TD
    LOGIN["🏢 Login as Organization"] --> HOME["OrganizationScreen\n3 Tabs"]

    HOME --> TAB0["Tab 0: แผนที่ 🗺️\nMapHomeScreen"]
    HOME --> TAB1["Tab 1: หน้าหลัก 🏠"]
    HOME --> TAB2["Tab 2: โปรไฟล์ 👤"]

    %% Map Tab
    TAB0 --> MAP_VIEW["Google Maps\nแสดง markers ปัญหาชุมชนทั้งหมด"]
    MAP_VIEW --> FILTER["FilterPanel\nกรอง category: flood/trash/traffic\ninfrastructure/other\nกรอง status: pending/inProgress/resolved"]
    MAP_VIEW --> MARKER["กด marker\n→ ProblemDetailScreen\nดูรายละเอียดปัญหา"]
    MARKER --> UPDATE_STATUS["เปลี่ยนสถานะปัญหา\nPUT /api/problems/:id/status\npending → inProgress → resolved\nEvent: problem.status.changed\n→ Notification เจ้าของปัญหา"]

    %% Home Tab
    TAB1 --> BANNER["Banner carousel\nประกาศหน่วยงาน"]
    TAB1 --> QMENU{Quick Menu}
    QMENU --> ADD_ACT["➕ เพิ่มกิจกรรม\n→ AddActivityScreen\n(เหมือนครู)"]
    QMENU --> REVIEW["📝 ตรวจงาน\n→ ReviewWorksScreen\n(เหมือนครู)"]
    QMENU --> CHAT["💬 แชท\n→ TicketListScreen"]

    ADD_ACT --> ACT_FORM["กรอกฟอร์มกิจกรรม\n+ ปักหมุดแผนที่\n+ อัพโหลดรูป\nPOST /api/activities"]
    REVIEW --> MY_ACTS["ดูกิจกรรมที่สร้าง\n→ ดู submissions\n→ ให้คะแนน pass/fail"]

    %% Calendar section
    TAB1 --> CAL["📅 ปฏิทินกิจกรรม\nแสดงกิจกรรมที่จะมาถึง"]

    %% Profile Tab
    TAB2 --> PROFILE["ดูโปรไฟล์\nชื่อหน่วยงาน · อีเมล\nGET /user/profile"]
    PROFILE --> EDIT_PROF["แก้ไขโปรไฟล์\nPUT /user/profile"]
    PROFILE --> LOGOUT["Logout\nลบ JWT"]
```

---

### Services (Domain Boundaries)

| Service | Port | Responsibility | Data Store |
|---------|------|----------------|------------|
| **Auth Service** | 8080 | Register / Login / Google OAuth / JWT / Profile | Postgres |
| **Image Service** | 8081 | Upload / Presign รูปทุกประเภท | MinIO + Postgres |
| **Problem Service** | 8083 | CRUD ปัญหาชุมชน + PostGIS query | Postgres + PostGIS |
| **Activity Service** | 8084 | กิจกรรมโรงเรียน, ลงทะเบียน, ถอนลงทะเบียน, ส่งงาน, ตรวจงาน, ครูผู้ดูแล | Postgres |
| **Chat Service** | 8085 | WebSocket real-time + REST fallback, ห้องแชท auto-create, ส่งรูปในแชท | Postgres |
| **Notification** | 8086 | Push (FCM), Email — consume events | - |
| **Analytics** | 8087 | สรุปสถิติ, dashboard — consume events | Postgres |

### Event Topics

| Topic | Producer | Consumers |
|-------|----------|-----------|
| `user.registered` | Auth | Notification, Analytics |
| `problem.created` | Problem | Notification, Analytics |
| `problem.status.changed` | Problem | Notification (เจ้าของปัญหา) |
| `activity.created` | Activity | Notification (broadcast นักเรียน) |
| `activity.joined` | Activity | Notification (แจ้งครู) |
| `submission.reviewed` | Activity | Notification, Chat (ส่ง feedback อัตโนมัติ) |
| `chat.message.sent` | Chat | Notification (push offline user) |
| `image.uploaded` | Image | Problem / Activity (link metadata) |

### WebSocket Chat Flow

```mermaid
sequenceDiagram
    participant C as Flutter Client
    participant WS as Chat Service :8085
    participant DB as PostgreSQL
    participant KB as Kafka (Redpanda)
    participant N as Notification Service

    C->>WS: ws://host:8085/ws?token=JWT
    WS-->>C: {"type":"connected","user_id":"3"}

    C->>WS: {"type":"send_message","payload":{"to_user_id":"1","content":"สวัสดี"}}
    WS->>DB: findOrCreateRoom(sender, receiver)
    WS->>DB: INSERT message
    WS->>KB: publish chat.message.sent
    WS-->>C: {"type":"new_message","message":{...}}
    WS-->>C: broadcast → UserB (all connections)

    Note over C,N: Fallback: ถ้า WS ไม่พร้อม → REST POST /api/chat/messages
    KB->>N: consume chat.message.sent
    N-->>C: FCM push (ถ้า UserB offline)
```

**Fallback:** ถ้า WebSocket ยังไม่ connected จะ fallback ใช้ REST API `POST /api/chat/messages` แทน แล้ว broadcast ผ่าน WebSocket Hub ให้อีกฝั่ง

### Auto-Create Chat Room (นักเรียนทักครู)

```mermaid
flowchart TD
    A["👨‍🎓 Student\nทักครู"] --> B["Chat Service :8085"]
    B --> C{มีห้อง student ↔ teacher\nแล้วหรือยัง?}
    C -->|ไม่มี| D["สร้างห้องใหม่ 1:1"]
    D --> E["publish chat.room.created"]
    C -->|มีแล้ว| F["reuse ห้องเดิม"]
    D --> G["บันทึกข้อความลง DB"]
    F --> G
    G --> H["broadcast ผ่าน WebSocket\nให้ทั้ง 2 ฝั่ง (ถ้า online)"]
    G --> I["publish chat.message.sent"]
    I --> J["Notification Service"]
    J --> K["ฝั่งไม่ online\n→ ส่ง FCM push 📲"]
```

### Communication Patterns

| รูปแบบ | ใช้เมื่อ | ตัวอย่าง |
|--------|---------|---------|
| **Sync (REST)** | ต้องการผลลัพธ์ทันที | Client → Service (CRUD) |
| **Async (Event Bus)** | งานที่ไม่ต้องรอ มี consumer หลายตัว | Notification, Analytics |
| **WebSocket** | Real-time bi-directional | Chat Service (send + receive messages) |

### Implementation Status

| Component | Status | Notes |
|-----------|--------|-------|
| Auth Service `:8080` | ✅ | publishes `user.registered` |
| Image Service `:8081` | ✅ | MinIO backend, presigned URLs |
| Problem Service `:8083` | ✅ | publishes `problem.created`, `problem.status.changed` |
| Activity Service `:8084` | ✅ | CRUD + register/unregister + submit + review + supervisor + map location |
| Chat Service `:8085` | ✅ | **WebSocket real-time** + REST fallback + image messages |
| Notification Service `:8086` | ✅ | consumes events, log-based (FCM/SMTP pending) |
| Analytics Service `:8087` | ✅ | consumes all events → Postgres `event_log` + `event_counts`, `GET /stats` |
| Event Bus | ✅ | Redpanda (Kafka API) via `segmentio/kafka-go` |

---

## Tech Stack Summary

```
Frontend:  Flutter + Provider + Google Maps + Auth0 + WebSocket
Backend:   Go Fiber v3 + GORM + JWT + bcrypt + fasthttp/websocket
Database:  PostgreSQL + PostGIS + uuid-ossp
Storage:   MinIO (S3-compatible)
Events:    Redpanda (Kafka API)
Auth:      Auth0 (Google OAuth2) + Local (email/password)
```

---

## Project Structure

### Entry Point

```
main.dart
  └─ CommunityReportApp (Provider wrapper: AuthService, ActivityService, ChatService, ProblemService)
     └─ AuthGate (ตรวจสอบสถานะ login)
        ├─ ยังไม่ login → WelcomeScreen
        └─ login แล้ว → HomeScreen (ตาม role)
```

---

## Screens

| ไฟล์ | Widget | หน้าที่ |
|------|--------|---------|
| `welcome_screen.dart` | `WelcomeScreen` | Onboarding carousel 4 หน้า |
| `login_screen.dart` | `LoginScreen` | เลือก role + ฟอร์ม login + Login with Google |
| `register_screen.dart` | `RegisterScreen` | สมัครสมาชิก |
| `map_screen.dart` | `MapHomeScreen` | Google Maps + custom markers ปัญหาชุมชน |
| `problem_detail_screen.dart` | `ProblemDetailScreen` | รายละเอียดปัญหา |
| `student/student_screen.dart` | `StudentScreen` | Dashboard นักเรียน + Bottom Navigation |
| `student/school_activities_screen.dart` | `SchoolActivitiesScreen` | รายการกิจกรรมโรงเรียน + ลงทะเบียน |
| `student/my_registrations_screen.dart` | `MyRegistrationsScreen` | กิจกรรมที่ลงทะเบียน (API จริง) + ถอนการลงทะเบียน + แผนที่สถานที่ + ส่งงาน + แชทกับครู |
| `student/chat_screen.dart` | `TicketListScreen` / `ChatRoomScreen` | ระบบแชท **WebSocket real-time** + ส่งรูปภาพ + REST fallback |
| `teacher/teacher_screen.dart` | `TeacherScreen` | Dashboard ครู + Bottom Navigation |
| `teacher/add_activity_screen.dart` | `AddActivityScreen` | ฟอร์มเพิ่มกิจกรรม + ปักหมุดแผนที่ + ครูผู้ดูแล + เบอร์ติดต่อ |
| `teacher/review_works_screen.dart` | `ReviewWorksScreen` | ตรวจงานนักเรียน (API จริง) — ดูกิจกรรมที่สร้าง, submissions, ให้คะแนน ผ่าน/ไม่ผ่าน |
| `organization/organization_screen.dart` | `OrganizationScreen` | Dashboard หน่วยงาน |

---

## Models

**`models/problem_report.dart`**
- `ProblemReport` - ข้อมูลปัญหา (id, title, description, location, status, imageUrls)
- `ProblemCategory` enum: flood, trash, traffic, infrastructure, other
- `ProblemStatus` enum: pending, inProgress, resolved
- `ProblemSource` enum: user, government, urgent

**`models/activity.dart`**
- `Activity` - ข้อมูลกิจกรรม (id, teacherId, title, description, location, **latitude, longitude, supervisor, supervisorPhone**, startAt, endAt, maxSlots, imageIds)
- `Registration` - ข้อมูลการลงทะเบียน + nested `Activity`
- `Submission` - ข้อมูลการส่งงาน (id, content, imageIds, score, feedback, status, **studentId, activityId**)

**`models/chat.dart`**
- `ChatRoom` - ห้องแชท (id, userA, userB)
- `ChatMessage` - ข้อความแชท (id, roomId, senderId, content, **imageId**, readAt)

---

## Services

**`services/api_config.dart`**
- `ApiConfig` - base URL ของแต่ละ service (auto-detect Android/iOS)

**`services/auth_service.dart`**
- `AuthService` (ChangeNotifier) - login/logout, JWT management
- `login()`, `register()`, `loginWithGoogle()`
- Properties: isLoggedIn, username, role, token, userId, avatarUrl, authHeaders

**`services/problem_service.dart`**
- `ProblemService` (ChangeNotifier) - CRUD ปัญหาชุมชน
- `fetchProblems()`, `createProblem()`, `updateProblemStatus()`

**`services/activity_service.dart`**
- `ActivityService` (ChangeNotifier) - จัดการกิจกรรม
- `fetchActivities()`, `createActivity()` (+ supervisor, location pin)
- `registerForActivity()`, `unregister()`
- `fetchMyRegistrations()`, `fetchMyActivitySubmissions()`
- `submitWork()`, `reviewSubmission()`
- `ActivityWithSubmissions` - model สำหรับครูดึงกิจกรรม+submissions

**`services/chat_service.dart`**
- `ChatService` (ChangeNotifier) - **WebSocket + REST fallback**
- `connectWebSocket()` - เชื่อม ws://host:8085/ws?token=xxx
- `sendMessageWs()` - ส่งผ่าน WS (fallback REST ถ้าไม่พร้อม)
- `onMessage` stream - broadcast ข้อความใหม่ real-time
- Auto-reconnect ทุก 3 วินาที + ping keep-alive ทุก 30 วินาที
- `fetchRooms()`, `fetchMessages()`, `sendMessage()` (REST)

---

## App Bootstrap & Auth Gate

คำอธิบาย: สิ่งที่เกิดขึ้นทุกครั้งที่เปิดแอป ก่อนเข้าสู่หน้าจอตาม role — เริ่มจาก `main()` ไปจนถึง `AuthGate` ตัดสินใจว่าจะแสดงหน้าไหน

```mermaid
flowchart LR
    GATE["AuthGate"] --> WELCOME["WelcomeScreen"]
    WELCOME --> LOGIN["LoginScreen"]
    LOGIN --> REGISTER["RegisterScreen"]

    GATE --> STUDENT["StudentScreen"]
    STUDENT --> MAPVIEW["MapView"]
    MAPVIEW --> DETAIL["DetailScreen"]
    DETAIL --> REGISTER_FORM["ActivityRegisterForm"]
    STUDENT --> SCHOOL_ACT["SchoolActivitiesScreen"]
    SCHOOL_ACT --> ACT_DETAIL["ActivityDetailScreen"]
    ACT_DETAIL --> ACT_REGISTER["ActivityRegisterScreen"]
    STUDENT --> MY_REG["MyRegistrationsScreen"]
    MY_REG --> REG_DETAIL["RegistrationDetailScreen"]
    REG_DETAIL --> CHATROOM["ChatRoomScreen"]
    STUDENT --> SETTINGS["SettingsScreen"]

    GATE --> TEACHER["TeacherScreen"]
    TEACHER --> SCHOOL_ACT
    TEACHER --> ADD_ACT["AddActivityScreen"]
    ADD_ACT --> LOCATION_PICKER["LocationPickerScreen"]
    TEACHER --> REVIEW["ReviewWorksScreen"]
    REVIEW --> SUBMISSIONS["SubmissionsScreen"]
    SUBMISSIONS --> REVIEW_DETAIL["ReviewDetailScreen"]
    TEACHER --> TICKETS["TicketListScreen"]
    TICKETS --> CHATROOM
    TEACHER --> SETTINGS

    GATE --> ORG["OrganizationScreen"]
    ORG --> MAPVIEW
    ORG --> ADD_ACT
    ORG --> REVIEW
    ORG --> TICKETS
    ORG --> SETTINGS
```

`AuthService` โหลด role ที่บันทึกไว้ใน `SharedPreferences` (`user_role`) ตอนเปิดแอปใหม่ จึงข้าม WelcomeScreen/LoginScreen ไปหน้าตาม role ได้ทันทีถ้าเคย login ค้างไว้

---

## Navigation Flow

```mermaid
flowchart TD
    A["WelcomeScreen\nOnboarding 4 หน้า"] --> B["LoginScreen\nเลือก Role"]

    B -->|student| S["StudentScreen 🎓"]
    B -->|teacher| T["TeacherScreen 👩‍🏫"]
    B -->|organization| O["OrganizationScreen 🏢"]

    subgraph STUDENT["Student Dashboard"]
        S --> S0["Tab 0: MapHomeScreen\nแผนที่ + markers"]
        S --> S1["Tab 1: Activities"]
        S --> S2["Tab 2: Profile → Logout"]
        S1 --> S1A["SchoolActivitiesScreen\n→ ลงทะเบียน"]
        S1 --> S1B["MyRegistrationsScreen"]
        S1B --> S1B1["ดูรายละเอียด + แผนที่"]
        S1B --> S1B2["ส่งงาน (แนบไฟล์)"]
        S1B --> S1B3["ถอนการลงทะเบียน"]
        S1B --> S1B4["ChatRoomScreen\n(WebSocket) 💬"]
    end

    subgraph TEACHER["Teacher Dashboard"]
        T --> T0["Tab 0: SchoolActivitiesScreen"]
        T --> T1["Tab 1: Home"]
        T --> T2["Tab 2: Profile"]
        T1 --> T1A["AddActivityScreen\n+ map pin + ครูผู้ดูแล"]
        T1 --> T1B["ReviewWorksScreen\nตรวจงาน + ให้คะแนน"]
        T1 --> T1C["TicketListScreen\n→ ChatRoomScreen 💬"]
    end

    subgraph ORG["Organization Dashboard"]
        O --> O0["Tab 0: MapHomeScreen"]
        O --> O1["Tab 1: Home (เมนูลัด)"]
        O --> O2["Tab 2: Profile"]
    end
```

---

## Backend API Endpoints

### Auth Service (`:8080`)

| Method | Path | หน้าที่ | Auth |
|--------|------|---------|------|
| POST | `/auth/register` | สมัครสมาชิก | - |
| POST | `/auth/login` | Login | - |
| POST | `/auth/google` | Login ด้วย Google (Auth0) | - |
| GET | `/user/profile` | ดูโปรไฟล์ | JWT |
| PUT | `/user/profile` | อัพเดทโปรไฟล์ | JWT |

### Image Service (`:8081`)

| Method | Path | หน้าที่ | Auth |
|--------|------|---------|------|
| POST | `/api/images` | Upload รูป (multipart, max 30MB) | JWT |
| GET | `/api/images` | List รูปของ user | JWT |
| GET | `/api/images/:id` | ดู metadata | JWT |
| GET | `/api/images/:id/url` | Presigned URL (15 นาที) | JWT |
| DELETE | `/api/images/:id` | ลบรูป | JWT |

### Problem Service (`:8083`)

| Method | Path | หน้าที่ | Auth |
|--------|------|---------|------|
| GET | `/api/problems` | ดูรายการปัญหา | - |
| GET | `/api/problems/:id` | ดูรายละเอียด | - |
| POST | `/api/problems` | สร้างรายงานปัญหา | JWT |
| PUT | `/api/problems/:id/status` | เปลี่ยนสถานะ | JWT |
| DELETE | `/api/problems/:id` | ลบปัญหา | JWT |

### Activity Service (`:8084`)

| Method | Path | หน้าที่ | Auth |
|--------|------|---------|------|
| GET | `/api/activities` | ดูรายการกิจกรรม | - |
| GET | `/api/activities/my-registrations` | รายการที่ลงทะเบียน (+ nested activity) | JWT |
| GET | `/api/activities/my-submissions` | กิจกรรมของครู + submissions | JWT |
| GET | `/api/activities/:id` | ดูรายละเอียดกิจกรรม | JWT |
| POST | `/api/activities` | สร้างกิจกรรม (+ supervisor, lat/lng) | JWT |
| POST | `/api/activities/:id/register` | ลงทะเบียน | JWT |
| DELETE | `/api/activities/registrations/:regId` | **ถอนการลงทะเบียน** | JWT |
| POST | `/api/activities/registrations/:regId/submit` | ส่งงาน | JWT |
| PUT | `/api/activities/submissions/:subId/review` | ตรวจงาน + ให้คะแนน | JWT |

### Chat Service (`:8085`)

| Method | Path | หน้าที่ | Auth |
|--------|------|---------|------|
| GET | `/api/chat/rooms` | ดูห้องแชท | JWT |
| POST | `/api/chat/messages` | ส่งข้อความ (+ image_id) REST fallback | JWT |
| GET | `/api/chat/rooms/:roomId/messages` | ดูข้อความในห้อง | JWT |
| WS | `/ws?token=<JWT>` | **WebSocket real-time messaging** | Query param |

**WebSocket Events:**

| Direction | Type | Payload |
|-----------|------|---------|
| Client → Server | `send_message` | `{to_user_id, content, image_id?}` |
| Client → Server | `ping` | - |
| Server → Client | `connected` | `{user_id}` |
| Server → Client | `new_message` | `{message, room_id}` |
| Server → Client | `pong` | - |

---

## Database Schema

**`server/postgres-init/`** — แยก schema ตาม service (database-per-service)

### Activities Table

| Column | Type | Notes |
|--------|------|-------|
| id | UUID | PK, auto-generate |
| teacher_id | VARCHAR(64) | FK to user |
| title | VARCHAR(255) | |
| description | TEXT | |
| location | VARCHAR(255) | ชื่อสถานที่ |
| latitude | DOUBLE PRECISION | พิกัดแผนที่ |
| longitude | DOUBLE PRECISION | พิกัดแผนที่ |
| supervisor | VARCHAR(255) | ชื่อครูผู้ดูแล |
| supervisor_phone | VARCHAR(50) | เบอร์ติดต่อ |
| start_at | TIMESTAMPTZ | |
| end_at | TIMESTAMPTZ | |
| max_slots | INTEGER | จำนวนรับ |
| image_ids | TEXT[] | |

### Chat Messages Table

| Column | Type | Notes |
|--------|------|-------|
| id | UUID | PK |
| room_id | UUID | FK to rooms |
| sender_id | VARCHAR(64) | |
| content | TEXT | |
| image_id | VARCHAR(255) | รูปภาพในแชท (FK to images) |
| read_at | TIMESTAMPTZ | nullable |
| created_at | TIMESTAMPTZ | |

---

## Dependencies หลัก

### Flutter

| Package | ใช้ทำอะไร |
|---------|-----------|
| `provider` | State management |
| `google_maps_flutter` | แผนที่ + markers |
| `geolocator` | ตำแหน่งปัจจุบัน |
| `shared_preferences` | เก็บ session |
| `image_picker` | เลือกรูปจากกล้อง/แกลเลอรี |
| `http` | HTTP client |
| `web_socket_channel` | WebSocket client (chat) |
| `http_parser` | MediaType for multipart upload |
| `flutter_appauth` | Auth0 / Google OAuth |
| `file_picker` | เลือกไฟล์ส่งงาน |

### Go Backend

| Package | ใช้ทำอะไร |
|---------|-----------|
| `gofiber/fiber/v3` | Web framework |
| `fasthttp/websocket` | WebSocket server (chat) |
| `golang-jwt/jwt/v5` | JWT auth |
| `gorm.io/gorm` + `driver/postgres` | ORM + PostgreSQL |
| `golang.org/x/crypto` | bcrypt |
| `minio/minio-go/v7` | MinIO client (images) |
| `segmentio/kafka-go` | Kafka client (events) |
| `google/uuid` | UUID generation |

---

## Run Locally

```bash
# 1. Tidy Go modules
cd server && ./bootstrap.sh && cd ..

# 2. Bring up infrastructure + all services
docker compose up --build

# 3. Run Flutter app
cd app && flutter run
```

### UIs
- Redpanda Console — http://localhost:8088
- MinIO Console — http://localhost:9001 (`minioadmin` / `minioadmin`)
- Analytics stats — http://localhost:8087/stats

---

## File Tree

```
app/lib/
├── main.dart
├── models/
│   ├── problem_report.dart
│   ├── activity.dart          # Activity + Registration + Submission
│   └── chat.dart              # ChatRoom + ChatMessage (+ imageId)
├── screens/
│   ├── welcome_screen.dart
│   ├── login_screen.dart
│   ├── register_screen.dart
│   ├── map_screen.dart
│   ├── problem_detail_screen.dart
│   ├── student/
│   │   ├── student_screen.dart
│   │   ├── school_activities_screen.dart
│   │   ├── my_registrations_screen.dart   # API จริง + ถอนลงทะเบียน
│   │   └── chat_screen.dart               # WebSocket real-time
│   ├── teacher/
│   │   ├── teacher_screen.dart
│   │   ├── add_activity_screen.dart       # + map pin + ครูผู้ดูแล
│   │   └── review_works_screen.dart       # API จริง + ตรวจงาน
│   └── organization/
│       └── organization_screen.dart
├── services/
│   ├── api_config.dart
│   ├── auth_service.dart
│   ├── problem_service.dart
│   ├── activity_service.dart              # + unregister + fetchMyActivitySubmissions
│   └── chat_service.dart                  # WebSocket + REST fallback
├── theme/
│   └── app_theme.dart
└── widgets/
    ├── problem_bottom_sheet.dart
    ├── filter_panel.dart
    └── add_problem_sheet.dart

server/
├── login/          # Auth Service :8080
├── image/          # Image Service :8081 (MinIO)
├── problem/        # Problem Service :8083
├── activity/       # Activity Service :8084
├── chat/           # Chat Service :8085 (WebSocket + REST)
│   └── handlers/
│       ├── chat.go   # REST handlers
│       └── ws.go     # WebSocket Hub + handler
├── notification/   # Notification Service :8086
├── analytics/      # Analytics Service :8087
├── shared/         # Shared event library (Kafka)
├── postgres-init/  # Database init scripts
├── docker-compose.yml
└── Dockerfile
```
