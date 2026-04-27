from sqlalchemy import text
from sqlgen import AsyncRepository

from awefull_pizza_shop.database.models import Pizza


class PizzaRepository(AsyncRepository):
    cls = Pizza

    async def vulnerable_get_pizza_by_category(self, category):
        vulnerable_statement = self.statement_generator.get_by().filter(text(f"category='{category}'"))
        return await self.statement_executor.all(vulnerable_statement)
