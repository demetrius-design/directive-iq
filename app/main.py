from fastapi import FastAPI, Request
from chains import run_orchestration

app = FastAPI(
    title="DirectiveIQ",
    version="1.0.0",
    description="Conversational logic-to-infrastructure orchestrator."
)

@app.post("/orchestrate")
async def orchestrate(request: Request):
    body = await request.json()
    prompt = body.get("prompt")

    if not prompt:
        return {"error": "Missing 'prompt' in request body."}

    result = run_orchestration(prompt)
    return {"result": result}
