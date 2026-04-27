from sqlgen import AsyncRepository

from awefull_pizza_shop.database.models import User


class UserRepository(AsyncRepository):
    cls = User
