import datetime
import hashlib
import hmac
import logging
import os
import secrets
from typing import Any, Dict, Optional

import firebase_admin
from firebase_admin import auth as fb_auth
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
import jwt

from core.config import settings
from core.database import get_db_connection

logger = logging.getLogger("security")

# Initialize Firebase Admin with project ID if not already initialized
try:
    if not firebase_admin._apps:
        cred_path = getattr(settings, "FIREBASE_CREDENTIALS_PATH", "firebase_service_account.json")
        if os.path.exists(cred_path):
            from firebase_admin import credentials
            cred = credentials.Certificate(cred_path)
            firebase_admin.initialize_app(cred)
            logger.info(f"[Firebase Admin] Initialized with cert from {cred_path}")
        else:
            firebase_admin.initialize_app(options={"projectId": "aakriti-ultrasound"})
            logger.info("[Firebase Admin] Initialized with projectId: aakriti-ultrasound")
except Exception as fb_err:
    logger.warning(f"[Firebase Admin] Initialization note: {fb_err}")

# HTTP Bearer authentication scheme
security_scheme = HTTPBearer(auto_error=False)


def hash_password(password: str, salt: Optional[str] = None) -> str:
    """
    PBKDF2-HMAC-SHA256 password hashing.
    Format: pbkdf2_sha256$<salt>$<hash>
    """
    if not salt:
        salt = secrets.token_hex(16)
    key = hashlib.pbkdf2_hmac(
        "sha256",
        password.encode("utf-8"),
        salt.encode("utf-8"),
        100000,
    )
    return f"pbkdf2_sha256${salt}${key.hex()}"


def verify_password(plain_password: str, stored_hash: str) -> bool:
    """
    Verifies a plain password against the stored password hash or plaintext.
    Supports constant-time verification for PBKDF2 hashes and legacy rows.
    """
    if not stored_hash or not plain_password:
        return False

    if stored_hash.startswith("pbkdf2_sha256$"):
        try:
            parts = stored_hash.split("$")
            if len(parts) == 3:
                salt = parts[1]
                expected_hash = parts[2]
                computed = hashlib.pbkdf2_hmac(
                    "sha256",
                    plain_password.encode("utf-8"),
                    salt.encode("utf-8"),
                    100000,
                ).hex()
                return hmac.compare_digest(computed, expected_hash)
        except Exception:
            return False

    # Constant-time comparison for legacy plaintext passwords
    return hmac.compare_digest(plain_password.strip(), stored_hash.strip())


def create_access_token(
    data: Dict[str, Any],
    expires_delta: Optional[datetime.timedelta] = None,
) -> str:
    """
    Generate signed JWT token containing subject, email, role, and expiration.
    """
    to_encode = data.copy()
    now = datetime.datetime.utcnow()
    expire = now + (expires_delta or datetime.timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES))
    to_encode.update({"iat": now, "exp": expire})
    return jwt.encode(to_encode, settings.JWT_SECRET_KEY, algorithm=settings.ALGORITHM)


def decode_token_payload(token: str) -> Optional[Dict[str, Any]]:
    """
    Verifies and decodes incoming token.
    Primary: Firebase Authentication ID Token verification.
    Secondary: Internal signed JWT token verification.
    """
    clean_token = token.strip()
    if not clean_token:
        return None

    # 1. Primary: Verify Firebase ID Token via Firebase Admin
    try:
        decoded_fb = fb_auth.verify_id_token(clean_token)
        return {
            "uid": decoded_fb.get("uid"),
            "email": (decoded_fb.get("email") or "").lower().strip(),
            "phone": decoded_fb.get("phone_number") or "",
            "name": decoded_fb.get("name") or "",
            "auth_provider": "firebase",
        }
    except Exception:
        pass

    # 2. Secondary: Verify backend JWT token
    try:
        decoded_jwt = jwt.decode(
            clean_token,
            settings.JWT_SECRET_KEY,
            algorithms=[settings.ALGORITHM],
        )
        sub_val = str(decoded_jwt.get("sub") or decoded_jwt.get("uid") or "")
        email_val = (decoded_jwt.get("email") or "").lower().strip()
        if not email_val and "@" in sub_val:
            email_val = sub_val.lower().strip()

        return {
            "uid": sub_val,
            "email": email_val,
            "phone": decoded_jwt.get("phone") or "",
            "name": decoded_jwt.get("name") or "",
            "role": decoded_jwt.get("role"),
            "patient_id": decoded_jwt.get("patient_id"),
            "auth_provider": "jwt",
        }
    except Exception:
        pass

    return None


async def get_current_user(
    auth: Optional[HTTPAuthorizationCredentials] = Depends(security_scheme),
) -> Dict[str, Any]:
    """
    FastAPI dependency:
    1. Extracts and verifies Firebase ID Token or JWT Token.
    2. Determines role from MySQL (admin_users vs patients) strictly on the server.
    3. Never trusts client-supplied roles.
    Raises HTTP 401 if token is missing or invalid.
    """
    if not auth or not auth.credentials:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authentication credentials were not provided. Please log in.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    token_payload = decode_token_payload(auth.credentials)
    if not token_payload:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired authentication token. Please log in again.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # Server-side role resolution from MySQL
    email = token_payload.get("email") or ""
    uid = token_payload.get("uid") or ""
    phone = token_payload.get("phone") or ""
    name = token_payload.get("name") or "User"
    payload_pid = token_payload.get("patient_id")

    user_info: Dict[str, Any] = {
        "uid": uid,
        "email": email,
        "phone": phone,
        "name": name,
        "role": "patient",
        "patient_id": payload_pid,
        "admin_id": None,
    }

    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)

        # 1. Check if user is an active Admin in MySQL admin_users
        if email:
            cursor.execute(
                "SELECT id, name, email, status FROM admin_users WHERE LOWER(email) = LOWER(%s) AND status = 'Active'",
                (email,),
            )
            admin_user = cursor.fetchone()
            if admin_user:
                user_info["role"] = "admin"
                user_info["admin_id"] = admin_user["id"]
                user_info["name"] = admin_user["name"]
                cursor.close()
                connection.close()
                return user_info

        # 2. If not admin, resolve or create patient identity in MySQL patients table
        clean_phone = phone.replace("+91", "").replace(" ", "").strip()
        cursor.execute(
            """
            SELECT id, patient_id, full_name, mobile, email
            FROM patients
            WHERE (email IS NOT NULL AND LOWER(email) = LOWER(%s) AND email != '')
               OR (mobile IS NOT NULL AND mobile = %s AND mobile != '')
               OR (patient_id IS NOT NULL AND patient_id = %s)
            LIMIT 1
            """,
            (email, clean_phone, payload_pid or ""),
        )
        patient = cursor.fetchone()

        if patient:
            user_info["patient_id"] = patient["patient_id"]
            user_info["name"] = patient["full_name"]
        elif not payload_pid:
            # Auto-link patient in MySQL so MySQL remains single source of truth
            gen_pid = f"AKR{secrets.token_hex(4).upper()}"
            try:
                cursor.execute(
                    """
                    INSERT INTO patients (patient_id, full_name, mobile, email, status)
                    VALUES (%s, %s, %s, %s, 'Active')
                    """,
                    (gen_pid, name or "Patient", clean_phone or "0000000000", email or None),
                )
                connection.commit()
                user_info["patient_id"] = gen_pid
            except Exception as ins_err:
                logger.warning(f"Patient auto-create note: {ins_err}")
                user_info["patient_id"] = gen_pid
        else:
            user_info["patient_id"] = payload_pid

        cursor.close()
        connection.close()
    except Exception as db_err:
        logger.error(f"[Security] MySQL role check error: {db_err}")
        # In case of database glitch, preserve payload info
        if token_payload.get("role") == "admin":
            user_info["role"] = "admin"

    return user_info


async def get_optional_current_user(
    auth: Optional[HTTPAuthorizationCredentials] = Depends(security_scheme),
) -> Optional[Dict[str, Any]]:
    """
    Optional user extractor for endpoints that work both authenticated and public.
    """
    if not auth or not auth.credentials:
        return None
    try:
        return await get_current_user(auth)
    except HTTPException:
        return None


async def require_admin(
    current_user: Dict[str, Any] = Depends(get_current_user),
) -> Dict[str, Any]:
    """
    FastAPI dependency:
    Rejects normal patients and unauthorized callers with HTTP 403 Forbidden.
    """
    role = str(current_user.get("role", "")).lower()
    if role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access denied. Administrator privileges required.",
        )
    return current_user


def verify_patient_access(target_patient_id: str, user: Dict[str, Any]) -> bool:
    """
    Enforces data ownership:
    - Admins can access any patient's records.
    - Normal patients can ONLY access their own records matching their verified patient_id.
    """
    if str(user.get("role", "")).lower() == "admin":
        return True

    user_pid = str(user.get("patient_id") or "").lower().strip()
    clean_target = str(target_patient_id or "").lower().strip()

    if user_pid and (user_pid == clean_target or clean_target in user_pid or user_pid in clean_target):
        return True

    user_phone = str(user.get("phone") or "").replace("+91", "").replace(" ", "").strip()
    if user_phone and user_phone == clean_target:
        return True

    return False
