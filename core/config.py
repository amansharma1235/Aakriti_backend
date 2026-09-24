import os
import urllib.parse
from dotenv import load_dotenv

# Load .env file
load_dotenv()

class Settings:
    PROJECT_NAME: str = "Aakriti Ultrasound & Diagnostic API"
    VERSION: str = "2.0.0"
    
    # MySQL Database Connection (Supports standard vars, Railway/Aiven vars, or full DATABASE_URL)
    @property
    def _db_url_env(self) -> str:
        url = os.getenv("DATABASE_URL") or os.getenv("MYSQL_URL") or ""
        if not url and (os.getenv("RENDER") or os.getenv("PORT")):
            return "mysql+pymysql://ZqAckF2JYGgphqR.root:lSTGSvIfa8gqj29s@gateway01.ap-southeast-1.prod.aws.tidbcloud.com:4000/aakriti_ultrasound"
        return url

    @property
    def MYSQL_HOST(self) -> str:
        if self._db_url_env:
            try:
                parsed = urllib.parse.urlparse(self._db_url_env)
                if parsed.hostname:
                    return parsed.hostname
            except Exception:
                pass
        return os.getenv("MYSQL_HOST") or os.getenv("MYSQLHOST") or "localhost"

    @property
    def MYSQL_PORT(self) -> int:
        if self._db_url_env:
            try:
                parsed = urllib.parse.urlparse(self._db_url_env)
                if parsed.port:
                    return parsed.port
            except Exception:
                pass
        return int(os.getenv("MYSQL_PORT") or os.getenv("MYSQLPORT") or 3306)

    @property
    def MYSQL_USER(self) -> str:
        if self._db_url_env:
            try:
                parsed = urllib.parse.urlparse(self._db_url_env)
                if parsed.username:
                    return urllib.parse.unquote(parsed.username)
            except Exception:
                pass
        return os.getenv("MYSQL_USER") or os.getenv("MYSQLUSER") or "root"

    @property
    def MYSQL_PASSWORD(self) -> str:
        if self._db_url_env:
            try:
                parsed = urllib.parse.urlparse(self._db_url_env)
                if parsed.password:
                    return urllib.parse.unquote(parsed.password)
            except Exception:
                pass
        return os.getenv("MYSQL_PASSWORD") or os.getenv("MYSQLPASSWORD") or "aman7800839003@"

    @property
    def MYSQL_DATABASE(self) -> str:
        if self._db_url_env:
            try:
                parsed = urllib.parse.urlparse(self._db_url_env)
                if parsed.path and len(parsed.path) > 1:
                    return parsed.path.lstrip("/").split("?")[0]
            except Exception:
                pass
        return os.getenv("MYSQL_DATABASE") or os.getenv("MYSQLDATABASE") or "aakriti_ultrasound"

    @property
    def DATABASE_URL(self) -> str:
        if self._db_url_env:
            url = self._db_url_env
            if url.startswith("mysql://"):
                url = url.replace("mysql://", "mysql+pymysql://", 1)
            return url
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
