from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.exc import SQLAlchemyError
from starlette.requests import Request
from starlette.responses import JSONResponse

from awefull_pizza_shop.webserver.config import settings
from awefull_pizza_shop.webserver.routers import user, security, pizza, comment


def register_error_handlers(app: FastAPI):
    @app.exception_handler(UnicodeDecodeError)
    async def unicorn_exception_handler(request: Request, exc: UnicodeDecodeError):
        return JSONResponse(
            status_code=400,
            content={"message": f"Invalid Data"},
        )

    @app.exception_handler(SQLAlchemyError)
    async def unicorn_exception_handler(request: Request, exc: UnicodeDecodeError):
        return JSONResponse(
            status_code=400,
            content={"message": f"Invalid Data"},
        )


def create() -> FastAPI:
    app = FastAPI(root_path=settings.ROOT_PATH)
    app.include_router(user.router)
    app.include_router(security.router)
    app.include_router(pizza.router)
    app.include_router(comment.router)

    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.ALLOWED_ORIGINS,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
    return app


if __name__ == '__main__':
    import uvicorn

    uvicorn.run(create(), host=str(settings.BIND_HOST), port=settings.BIND_PORT, root_path=settings.ROOT_PATH, **settings.UVICORN_KWARGS)
