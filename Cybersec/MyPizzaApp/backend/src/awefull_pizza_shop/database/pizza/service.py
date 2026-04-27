from typing import Optional
from uuid import UUID

from sqlalchemy.ext.asyncio import AsyncSession

from awefull_pizza_shop.database.models import Pizza
from awefull_pizza_shop.database.pizza.repository import PizzaRepository
from awefull_pizza_shop.database.service import DatabaseService
from awefull_pizza_shop.webserver import schemas


class PizzaService(DatabaseService):
    repository: PizzaRepository

    @staticmethod
    def from_session(session: AsyncSession):
        return PizzaService(PizzaRepository(session))

    def __init__(self, repository: PizzaRepository):
        super().__init__(repository)

    async def take_pizza_by_id(self, pizza_id: UUID, load_all: bool = False) -> Optional[Pizza]:
        return await self.repository.take_by_id(pizza_id, load_all=load_all)

    async def create_pizza(self, *, pizza: schemas.PizzaCreation) -> Pizza:
        """
        create a pizza in database and commit or rollback
        :param pizza: the pizza data
        :return: the created pizza model
        """
        pizza = await self.repository.create(
            name=pizza.name,
            description=pizza.description,
            price=pizza.price,
            image_url=pizza.image_url,
            category=pizza.category
        )
        return pizza

    async def get_pizzas(self) -> list[Pizza]:
        """
        get all pizzas in the database
        :return: a list of all pizzas in database
        """
        return await self.repository.get_all()

    async def vulnerable_get_pizza_by_category(self, category: str):
        return await self.repository.vulnerable_get_pizza_by_category(category)
