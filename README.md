# Aakriti Ultrasound & Diagnostics - Full Workspace

Complete codebase containing Admin Portal, User Mobile App, FastAPI Backend, and Firebase Configurations.

## Project Structure

```
├── aakriti_admin/                # Flutter Admin Application
├── aakriti_backend/              # FastAPI Python Backend (MySQL/TiDB + Render)
├── aakriti_user/                 # Flutter User/Patient Application
│   └── aakriti_ultrasound/
├── firebase.json                 # Firebase configuration
├── firestore.rules               # Firestore security rules
└── storage.rules                 # Firebase Storage security rules
```

## Subprojects Overview

### 1. `aakriti_backend`
- **Framework**: FastAPI (Python 3.11+)
- **Database**: MySQL / TiDB Cloud
- **Run command**: `uvicorn main:app --reload`
- **Deploy**: Render (`render.yaml`, `Procfile`)

### 2. `aakriti_admin`
- **Framework**: Flutter (Dart)
- **Features**: Patient queue management, test management, doctors schedule, clinic settings, reports upload.

### 3. `aakriti_user/aakriti_ultrasound`
- **Framework**: Flutter (Dart)
- **Features**: Patient portal, appointment booking, report downloads, family member management, QR passes.
