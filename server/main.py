from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from wakeonlan import send_magic_packet
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="Wake on WAN Server")

class WakeRequest(BaseModel):
    mac_address: str
    ip_address: str = "255.255.255.255" # Default broadcast
    port: int = 9 # Default WOL port

@app.get("/")
async def root():
    return {"message": "Wake on WAN Server is running"}

@app.post("/wake")
async def wake_computer(request: WakeRequest):
    try:
        logger.info(f"Sending Magic Packet to {request.mac_address} on {request.ip_address}:{request.port}")
        send_magic_packet(
            request.mac_address,
            ip_address=request.ip_address,
            port=request.port
        )
        return {"status": "success", "message": f"Magic packet sent to {request.mac_address}"}
    except Exception as e:
        logger.error(f"Error sending magic packet: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
