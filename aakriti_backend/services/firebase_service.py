import os
import logging
from typing import List, Dict, Any, Optional
from core.config import settings

logger = logging.getLogger("firebase_fcm")
logger.setLevel(logging.INFO)

firebase_initialized = False

try:
    import firebase_admin
    from firebase_admin import credentials, messaging

    cred_path = settings.FIREBASE_CREDENTIALS_PATH
    if os.path.exists(cred_path):
        cred = credentials.Certificate(cred_path)
        firebase_admin.initialize_app(cred)
        firebase_initialized = True
        logger.info(f"[Firebase] Initialized with credentials from {cred_path}")
    else:
        logger.info(f"[Firebase] Credentials file not found at {cred_path}. Operating in safe dev mode.")
except Exception as e:
    logger.warning(f"[Firebase] Initialization note: {e}. Safe fallback active.")

def is_firebase_ready() -> bool:
    return firebase_initialized

def send_push_notification(
    tokens: List[str],
    title: str,
    body: str,
    data: Optional[Dict[str, str]] = None
) -> Dict[str, Any]:
    """
    Send push notification via Firebase Admin SDK.
    Gracefully handles token failures and dev mode without throwing errors.
    """
    if not tokens:
        return {"success": False, "message": "No tokens provided", "count": 0}

    if not firebase_initialized:
        logger.info(f"[Firebase Safe-Mode] Would push: '{title}' - '{body}' to {len(tokens)} device(s)")
        return {"success": True, "message": "Safe mode mock dispatch", "count": len(tokens)}

    try:
        from firebase_admin import messaging
        message = messaging.MulticastMessage(
            notification=messaging.Notification(
                title=title,
                body=body,
            ),
            data=data or {},
            tokens=tokens,
        )
        response = messaging.send_each_for_multicast(message)
        logger.info(f"[Firebase] Successfully sent {response.success_count} notifications out of {len(tokens)}")
        return {
            "success": True,
            "success_count": response.success_count,
            "failure_count": response.failure_count,
        }
    except Exception as e:
        logger.error(f"[Firebase] FCM Send error: {e}")
        return {"success": False, "error": str(e), "count": 0}
