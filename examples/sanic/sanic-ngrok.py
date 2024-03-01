from sanic import Sanic
from sanic.response import text

app = Sanic("GoFast")

@app.get("/")
async def hello_world(request):
    return text("Gotta Go Fast! Sanic Speed!")
