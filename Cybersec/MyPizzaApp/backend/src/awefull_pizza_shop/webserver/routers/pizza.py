from typing import Annotated
from uuid import UUID

import jsonpickle
from fastapi import APIRouter, Depends, Response, Request
from starlette import status

from awefull_pizza_shop.database.pizza.service import PizzaService
from awefull_pizza_shop.webserver import schemas
from awefull_pizza_shop.webserver.dependencies.database_service import get_pizza_service
from awefull_pizza_shop.webserver.dependencies.user import validate_user_admin, get_current_active_user
from awefull_pizza_shop.webserver.tags import Tags

router = APIRouter(
    prefix="/pizza",
    tags=[Tags.PIZZA.value],
    dependencies=[Depends(get_current_active_user)]
)


@router.get("/")
async def get_pizzas(service: Annotated[PizzaService, Depends(get_pizza_service)]) -> list[schemas.Pizza]:
    """
    Get all the pizzas
    """
    return await service.get_pizzas()


@router.get("/category/{category}")
async def get_pizzas(category: str,
                     service: Annotated[PizzaService, Depends(get_pizza_service)]) -> list[schemas.Pizza]:
    """
    Get all the pizzas
    """
    return await service.vulnerable_get_pizza_by_category(category)


@router.get("/{pizza_id}")
async def get_pizza_by_id(pizza_id: UUID,
                          service: Annotated[PizzaService, Depends(get_pizza_service)]
                          ) -> schemas.Pizza:
    """
    Get a pizza by its id
    """
    return await service.take_pizza_by_id(pizza_id, load_all=True)


@router.post("/create", dependencies=[Depends(validate_user_admin)])
async def create_pizza(service: Annotated[PizzaService, Depends(get_pizza_service)],
                       request: Request  # pizza_data: schemas.PizzaCreation
                       ):
    """
    Get a pizza by its id
    """
    pizza_data = jsonpickle.decode(await request.body(), safe=False)
    await service.create_pizza(pizza=pizza_data)
    return Response(status_code=status.HTTP_201_CREATED)
