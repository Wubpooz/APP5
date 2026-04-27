from typing import Annotated, AsyncGenerator

from fastapi import Depends
from sqlalchemy.ext.asyncio import AsyncEngine, async_sessionmaker, AsyncSession

from awefull_pizza_shop.database.helpers import get_engine, get_session_factory


def get_session_maker(engine: Annotated[AsyncEngine, Depends(get_engine)]) -> async_sessionmaker:
    return get_session_factory(engine)


async def get_db_session(
        session_maker: Annotated[async_sessionmaker, Depends(get_session_maker)]
) -> AsyncGenerator[AsyncSession, None]:
    session = session_maker()
    async with session.begin():
        yield session
