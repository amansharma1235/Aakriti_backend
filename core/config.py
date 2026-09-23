import os
import urllib.parse
from dotenv import load_dotenv

# Load .env file
load_dotenv()

class Settings:
    PROJECT_NAME: str = "Aakriti Ultrasound & Diagnostic API"
    VERSION: str = "2.0.0"
    
    # MySQL Database Connection
    MYSQL_HOST: str = os.getenv("MYSQL_HOST", "localhost")
    MYSQL_PORT: int = int(os.getenv("MYSQL_PORT", 3306))
    MYSQL_USER: str = os.getenv("MYSQL_USER", "root")
    MYSQL_PASSWORD: str = os.getenv("MYSQL_PASSWORD", "aman7800839003@")
    MYSQL_DATABASE: str = os.getenv("MYSQL_DATABASE", "aakriti_ultrasound")
    
    @property
    def DATABASE_URL(self) -> str:
        # Properly URL-encode username and password to handle special chars like @, :, /
        encoded_user = urllib.parse.quote_plus(self.MYSQL_USER)
        encoded_password = urllib.parse.quote_plus(self.MYSQL_PASSWORD)
        return f"mysql+pymysql://{encoded_user}:{encoded_password}@{self.MYSQL_HOST}:{self.MYSQL_PORT}/{self.MYSQL_DATABASE}?charset=utf8mb4"

    # Security & JWT
    JWT_SECRET_KEY: str = os.getenv("JWT_SECRET_KEY", "aakriti_ultrasound_super_secret_jwt_key_2026")
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7  # 7 days

    # Default Admin Credentials
    ADMIN_EMAIL: str = os.getenv("ADMIN_EMAIL", "admin@aakriti.com")
    ADMIN_PASSWORD: str = os.getenv("ADMIN_PASSWORD", "admin123")

    # Firebase
    FIREBASE_CREDENTIALS_PATH: str = os.getenv("FIREBASE_CREDENTIALS_PATH", "firebase_service_account.json")

    # WebSocket & Server
    WS_HEARTBEAT_INTERVAL: int = 25  # seconds

settings = Settings()
