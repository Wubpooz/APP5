from typing import Annotated
from uuid import UUID

from awefull_pizza_shop.database.comment.repository import CommentRepository
from awefull_pizza_shop.database.comment.service import CommentService
from awefull_pizza_shop.database.pizza.repository import PizzaRepository
from awefull_pizza_shop.database.pizza.service import PizzaService
from awefull_pizza_shop.webserver.dependencies.database import get_db_session
from fastapi import Depends
from sqlalchemy.ext.asyncio import AsyncSession

from awefull_pizza_shop.database.user.repository import UserRepository
from awefull_pizza_shop.database.user.service import UserService
from awefull_pizza_shop.webserver.security.service import SecurityService


async def get_user_repository(session: Annotated[AsyncSession, Depends(get_db_session)]) -> UserRepository:
    return UserRepository(session)


async def get_user_service(repository: Annotated[UserRepository, Depends(get_user_repository)], ) -> UserService:
    return UserService(repository)


async def get_security_service(user_service: Annotated[UserService, Depends(get_user_service)]) -> SecurityService:
    return SecurityService(user_service)

async def get_pizza_repository(session: Annotated[AsyncSession, Depends(get_db_session)]) -> PizzaRepository:
    return PizzaRepository(session)


async def get_pizza_service(repository: Annotated[PizzaRepository, Depends(get_pizza_repository)], ) -> PizzaService:
    return PizzaService(repository)

async def get_comment_repository(session: Annotated[AsyncSession, Depends(get_db_session)],
                                 pizza_id: UUID) -> CommentRepository:
    return CommentRepository(session, pizza_id=pizza_id)


async def get_comment_service(repository: Annotated[CommentRepository, Depends(get_comment_repository)], ) -> CommentService:
    return CommentService(repository)