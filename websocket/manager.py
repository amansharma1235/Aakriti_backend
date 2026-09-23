import json
import logging
import datetime
from typing import List, Dict, Any, Optional
from fastapi import WebSocket, WebSocketDisconnect

logger = logging.getLogger("websocket")
logger.setLevel(logging.INFO)

class WebSocketManager:
    """
    Production-grade WebSocket manager for real-time diagnostic center events.
    Supports multiple connected admin dashboards, ping-pong heartbeats,
    and automatic cleanup of broken sockets.
    """
    def __init__(self):
        self.active_connections: List[WebSocket] = []
        self.connection_metadata: Dict[WebSocket, Dict[str, Any]] = {}

    async def connect(self, websocket: WebSocket, client_id: str = "Admin"):
        await websocket.accept()
        self.active_connections.append(websocket)
        self.connection_metadata[websocket] = {
            "client_id": client_id,
            "connected_at": datetime.datetime.utcnow().isoformat(),
            "last_ping": datetime.datetime.utcnow().isoformat(),
        }
        logger.info(f"[WS] Client connected: {client_id} (Total: {len(self.active_connections)})")

    def disconnect(self, websocket: WebSocket):
        if websocket in self.active_connections:
            self.active_connections.remove(websocket)
        if websocket in self.connection_metadata:
            meta = self.connection_metadata.pop(websocket)
            logger.info(f"[WS] Client disconnected: {meta.get('client_id')} (Remaining: {len(self.active_connections)})")

    async def send_personal_message(self, message: Dict[str, Any], websocket: WebSocket):
        try:
            await websocket.send_text(json.dumps(message))
        except Exception as e:
            logger.warning(f"[WS] Failed to send personal message: {e}")
            self.disconnect(websocket)

    async def broadcast(self, event_type: str, data: Dict[str, Any]):
        """
        Broadcast structured event to all connected admin dashboards.
        Does NOT block or throw if one connection fails.
        """
        payload = {
            "event": event_type,
            "type": event_type,
            "timestamp": datetime.datetime.utcnow().isoformat(),
            "data": data,
        }
        dead_connections = []
        for connection in list(self.active_connections):
            try:
                await connection.send_text(json.dumps(payload))
            except Exception as e:
                logger.warning(f"[WS] Broadcast error for a connection: {e}")
                dead_connections.append(connection)

        for dead in dead_connections:
            self.disconnect(dead)

    @property
    def connection_count(self) -> int:
        return len(self.active_connections)

ws_manager = WebSocketManager()
