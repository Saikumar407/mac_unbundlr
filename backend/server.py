from fastapi import FastAPI, APIRouter, HTTPException
from dotenv import load_dotenv
from starlette.middleware.cors import CORSMiddleware
from motor.motor_asyncio import AsyncIOMotorClient
import os
import json
import logging
from pathlib import Path
from pydantic import BaseModel, Field, ConfigDict
from typing import List, Optional, Literal
import uuid
from datetime import datetime, timezone

ROOT_DIR = Path(__file__).parent
load_dotenv(ROOT_DIR / '.env')

# MongoDB connection
mongo_url = os.environ['MONGO_URL']
client = AsyncIOMotorClient(mongo_url)
db = client[os.environ['DB_NAME']]

app = FastAPI(title="ProfilePilot Companion API")
api_router = APIRouter(prefix="/api")


# ---------- Models ----------
class StatusCheck(BaseModel):
    model_config = ConfigDict(extra="ignore")
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    client_name: str
    timestamp: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))


class StatusCheckCreate(BaseModel):
    client_name: str


class AIPlanItem(BaseModel):
    kind: Literal["browserProfile", "app", "url", "shell"]
    value: str
    delayMs: int = 300
    note: Optional[str] = None


class AIPlanResponse(BaseModel):
    name: str
    symbol: str
    items: List[AIPlanItem]


class AIPlanRequest(BaseModel):
    prompt: str
    hint: Optional[str] = None


class WorkspaceExport(BaseModel):
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    name: str
    symbol: str = "square.stack.3d.up"
    items: List[AIPlanItem]
    createdAt: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))


# ---------- Routes ----------
@api_router.get("/")
async def root():
    return {"message": "ProfilePilot Companion API"}


@api_router.post("/status", response_model=StatusCheck)
async def create_status_check(input: StatusCheckCreate):
    obj = StatusCheck(**input.model_dump())
    doc = obj.model_dump()
    doc['timestamp'] = doc['timestamp'].isoformat()
    await db.status_checks.insert_one(doc)
    return obj


@api_router.get("/status", response_model=List[StatusCheck])
async def get_status_checks():
    checks = await db.status_checks.find({}, {"_id": 0}).to_list(1000)
    for c in checks:
        if isinstance(c['timestamp'], str):
            c['timestamp'] = datetime.fromisoformat(c['timestamp'])
    return checks


# ---------- AI Workspace endpoint ----------
SYSTEM_PROMPT = """You are ProfilePilot's workspace planner. The user gives you a short
free-text description of a coding stack or activity. You reply with a compact JSON plan
describing a macOS workspace to launch.

Return JSON matching EXACTLY this schema (no markdown, no prose):

{
  "name": "<short workspace name>",
  "symbol": "<SF Symbol name>",
  "items": [
    {"kind": "app"|"url"|"shell"|"browserProfile", "value": "<string>", "delayMs": <int>, "note": "<optional short reason>"}
  ]
}

Rules:
- 4-9 items, ordered by launch order.
- Kind meanings:
    - app: absolute .app path (e.g. /Applications/Visual Studio Code.app)
    - url: full URL string
    - shell: shell command string
    - browserProfile: "com.google.Chrome::<profile-name>" e.g. "com.google.Chrome::Work"
- Prefer real, commonly-installed macOS apps: Visual Studio Code, iTerm, Terminal, Docker,
  Postman, TablePlus, Slack, Figma, ChatGPT, Cursor.
- Include a browserProfile item first when a browser is useful.
- Keep names, symbols, values short."""


async def call_llm(prompt: str, hint: Optional[str]) -> AIPlanResponse:
    """Uses emergentintegrations LlmChat to draft a plan."""
    from emergentintegrations.llm.chat import LlmChat, UserMessage
    api_key = os.environ.get("EMERGENT_LLM_KEY")
    if not api_key:
        raise HTTPException(500, "EMERGENT_LLM_KEY not configured on server.")

    session_id = f"pp-{uuid.uuid4()}"
    chat = (
        LlmChat(api_key=api_key, session_id=session_id, system_message=SYSTEM_PROMPT)
        .with_model("anthropic", "claude-sonnet-4-5-20250929")
    )
    user_text = prompt if not hint else f"{prompt}\n\nHint: {hint}"
    reply = await chat.send_message(UserMessage(text=user_text))

    text = reply.strip()
    # Strip potential markdown fences
    if text.startswith("```"):
        text = text.split("```", 2)[1]
        if text.startswith("json"):
            text = text[4:]
        text = text.strip("` \n")
    try:
        data = json.loads(text)
    except Exception as e:
        logging.error("LLM returned non-JSON: %s", text)
        raise HTTPException(502, f"LLM returned invalid JSON: {e}")
    return AIPlanResponse(**data)


@api_router.post("/ai-workspace", response_model=AIPlanResponse)
async def ai_workspace(req: AIPlanRequest):
    if not req.prompt.strip():
        raise HTTPException(400, "prompt is required")
    return await call_llm(req.prompt, req.hint)


@api_router.post("/workspaces/export", response_model=WorkspaceExport)
async def export_workspace(ws: WorkspaceExport):
    doc = ws.model_dump()
    doc['createdAt'] = doc['createdAt'].isoformat()
    await db.workspaces.insert_one(doc)
    return ws


@api_router.get("/workspaces", response_model=List[WorkspaceExport])
async def list_workspaces():
    items = await db.workspaces.find({}, {"_id": 0}).to_list(500)
    for it in items:
        if isinstance(it.get('createdAt'), str):
            it['createdAt'] = datetime.fromisoformat(it['createdAt'])
    return items


# ---------- Wire up ----------
app.include_router(api_router)

app.add_middleware(
    CORSMiddleware,
    allow_credentials=True,
    allow_origins=os.environ.get('CORS_ORIGINS', '*').split(','),
    allow_methods=["*"],
    allow_headers=["*"],
)

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)


@app.on_event("shutdown")
async def shutdown_db_client():
    client.close()
