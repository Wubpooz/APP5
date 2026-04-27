import os.path
from ipaddress import IPv4Address
from logging import getLogger
from typing import Any, Literal, Annotated

import yaml
from pydantic import Field, PostgresDsn, MySQLDsn, UrlConstraints
from pydantic_core import MultiHostUrl
from pydantic_settings import BaseSettings, SettingsConfigDict

logger = getLogger(__name__)

SQLiteDsn = Annotated[
    MultiHostUrl,
    UrlConstraints(
        host_required=False,
        allowed_schemes=[
            'sqlite',
            "sqlite+aiosqlite"
        ],
    ),
]
MSSQLDsn = Annotated[
    MultiHostUrl,
    UrlConstraints(
        host_required=True,
        allowed_schemes=[
            'mssql',
            'mssql+pyodbc',
            'mssql+pymssql',
            'mssql+aioodbc'
        ],
    ),
]


class WebserverSettings(BaseSettings):
    model_config = SettingsConfigDict(env_file='.env')

    JWT_ALGORITHM: Literal["HS256", "HS384", "HS512", "RS256", "RS384", "RS512", "ES256", "ES384", "ES512"] = "HS256"
    JWT_ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    JWT_SECRET_KEY: str = "changeme"

    BIND_HOST: IPv4Address = "0.0.0.0"
    BIND_PORT: int = 7465
    UVICORN_KWARGS: dict[str, Any] = Field(default_factory=dict)

    ALLOWED_ORIGINS: list[str] = [
        "http://127.0.0.1:4200",
        "http://localhost:4200",
        "http://0.0.0.0:4200"
    ]

    DATABASE_URL: PostgresDsn | MySQLDsn | SQLiteDsn | MSSQLDsn = "postgresql+asyncpg://pizzashop:pizzaShop@localhost/awefullpizzashop"
    DATABASE_KWARGS: dict[str, Any] = Field(default_factory=dict)

    ROOT_PATH: str = ""

    XSS_POLLER_URL:str="http://xss-poller:3000"

config_dict = {}
if os.path.isfile("config.yaml"):
    with open("config.yaml", "r") as file:
        config_dict = yaml.safe_load(file)
else:
    logger.info("no config file detected at %s/config.yaml", os.getcwd())

settings = WebserverSettings(**config_dict)
