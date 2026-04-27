from typing import Optional
from uuid import UUID

from sqlalchemy.ext.asyncio import AsyncSession

from awefull_pizza_shop.database.models import User
from awefull_pizza_shop.database.service import DatabaseService
from awefull_pizza_shop.database.user.repository import UserRepository
from awefull_pizza_shop.webserver import schemas
from awefull_pizza_shop.webserver.security.cryptography import get_password_hash


class UserService(DatabaseService):
    repository: UserRepository

    @staticmethod
    def from_session(session: AsyncSession):
        return UserService(UserRepository(session))

    def __init__(self, repository: UserRepository):
        super().__init__(repository)

    async def take_user_by_username(self, username: str, load_all: bool = False) -> Optional[User]:
        return await self.repository.take_by(name=username, load_all=load_all)

    async def take_user_by_id(self, user_id: UUID, load_all: bool = False) -> Optional[User]:
        return await self.repository.take_by_id(user_id, load_all=load_all)

    async def create_user(self, *, user: schemas.UserCreation) -> User:
        """
        create a user in database and commit or rollback
        :param user: the user data
        :return: the created user model
        """
        user = await self.repository.create(
            name=user.name,
            email=user.email,
            hashed_password=get_password_hash(user.password).encode(),
        )
        return user

    async def get_users(self) -> list[User]:
        """
        get all users in the database
        :return: a list of all users in database
        """
        return await self.repository.get_all()

    async def update_user(self, user_id: UUID, user_data: schemas.UserUpdate) -> None:
        await self.repository.update(user_id, save=True, name=user_data.name, email=user_data.email,
                                     role=user_data.role)
