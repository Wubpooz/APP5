from typing import Optional
from uuid import UUID

from sqlalchemy import Select
from sqlalchemy.ext.asyncio import create_async_engine, AsyncEngine, async_sessionmaker, AsyncSession
from sqlalchemy.sql.base import ExecutableOption

from awefull_pizza_shop.webserver.config import settings


async def get_by[T](session: AsyncSession, cls: type[T], options: list[ExecutableOption] = None,
                    **kwargs) -> Optional[T]:
    """
    generic function to get a model by the given properties
    :param session: the session to execute the query
    :param cls: the class of the object to search
    :param options: optional options for the query (mostly ofr joinedloads)
    :param kwargs: arguments to filter the model to return
    :return: the instance of the model if found in DB
    """
    statement = Select(cls).filter_by(**kwargs)
    if options:
        statement = statement.options(*options)
    return (await session.execute(statement)).unique().scalars().one_or_none()


async def get_by_id[T](session: AsyncSession, object_id: UUID, cls: type[T],
                       options: list[ExecutableOption] = None) -> Optional[T]:
    """
    generic function to get a model by its ID
    :param session: the session to execute the query
    :param object_id: the id of the object to query
    :param cls: the class of the object to search
    :param options: optional options for the query (mostly ofr joinedloads)
    :return: the instance of the model if found in DB
    """
    return await get_by(session, cls, options, id=object_id)


async def get_all_by[T](session: AsyncSession, cls: type[T], **kwargs) -> list[T]:
    """
    generic function to get all object of given model
    :param session: the session to execute the query
    :param cls: the class of the object to search
    :return: the list of instances of given model
    """
    statement = Select(cls).filter_by(**kwargs)
    return (await session.execute(statement)).scalars().all()


async def get_all[T](session: AsyncSession, cls: type[T]) -> list[T]:
    """
    generic function to get all object of given model
    :param session: the session to execute the query
    :param cls: the class of the object to search
    :return: the list of instances of given model
    """
    return await get_all_by(session, cls)


def get_engine() -> AsyncEngine:
    """
    helper to get a SQLAlchemy Engine using Configuration Provider
    :return: a SQLAlchemy Engine
    """
    if settings.DATABASE_URL is None:
        raise ValueError("No DATABASE_URL provided")
    return create_async_engine(
        str(settings.DATABASE_URL), **settings.DATABASE_KWARGS
    )


def get_session_factory(engine: AsyncEngine = None) -> async_sessionmaker:
    """
    helper to get a SQLAlchemy sessionmaker using Configuration Provider
    :return: a SQLAlchemy SessionMaker
    """
    if engine is None:
        engine = get_engine()
    return async_sessionmaker(autocommit=False, autoflush=False, expire_on_commit=False, bind=engine)


def get_db_session(session_factory: async_sessionmaker = None, engine: AsyncEngine = None) -> AsyncSession:
    """
    helper to get a SQLAlchemy session using Configuration Provider
    :return: a SQLAlchemy Session
    """
    if session_factory is None:
        session_factory = get_session_factory(engine)

    return session_factory()
