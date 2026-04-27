from dataclasses import dataclass
from typing import Annotated
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field
from pydantic_core import Url

from awefull_pizza_shop.database.models.pizza import PizzaCategory


class PizzaBase(BaseModel):
    name: str
    description: str
    price: float
    image_url: Annotated[Url, Field(serialization_alias="imageUrl")]


# class PizzaCreation(PizzaBase):
#    pass


class Pizza(PizzaBase):
    model_config = ConfigDict(from_attributes=True)
    id: UUID


# Pizza class for RCE
@dataclass
class PizzaCreation:
    name: str
    description: str
    price: float
    image_url: str
    category : PizzaCategory
