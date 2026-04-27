from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, Response
from starlette import status

from awefull_pizza_shop.database.user.service import UserService
from awefull_pizza_shop.webserver import schemas
from awefull_pizza_shop.webserver.dependencies.database_service import get_user_service
from awefull_pizza_shop.webserver.dependencies.user import validate_user_admin
from awefull_pizza_shop.webserver.tags import Tags

router = APIRouter(
    prefix="/users",
    tags=[Tags.USER.value, Tags.SECURITY.value],
    dependencies=[Depends(validate_user_admin)]
)


@router.get("/")
async def get_users(service: Annotated[UserService, Depends(get_user_service)]) -> list[schemas.User]:
    """
    Get all the users
    """
    return await service.get_users()


@router.get("/{user_id}")
async def get_user_by_id(user_id: UUID,
                         service: Annotated[UserService, Depends(get_user_service)]
                         ) -> schemas.User:
    """
    Get a user by its id
    """
    return await service.take_user_by_id(user_id, load_all=True)


@router.post("/{user_id}")
async def update_user_by_id(user_id: UUID,
                            service: Annotated[UserService, Depends(get_user_service)],
                            user_data: schemas.UserUpdate
                            ):
    """
    Get a user by its id
    """
    await service.update_user(user_id, user_data)
    return Response(status_code=status.HTTP_204_NO_CONTENT)
