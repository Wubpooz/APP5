from logging import getLogger
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Response
from fastapi.security import OAuth2PasswordRequestForm
from starlette import status

from awefull_pizza_shop.database.user.service import UserService
from awefull_pizza_shop.webserver import schemas
from awefull_pizza_shop.webserver.dependencies.database_service import get_security_service, get_user_service
from awefull_pizza_shop.webserver.security.service import SecurityService
from awefull_pizza_shop.webserver.tags import Tags

logger = getLogger(__name__)

router = APIRouter(
    prefix="",
    tags=[Tags.SECURITY.value, Tags.OAUTH2.value]
)

TOKEN_URL = "/token"
REGISTER_URL = "/register"


@router.post(TOKEN_URL)
async def login_for_access_token(form_data: Annotated[OAuth2PasswordRequestForm, Depends()],
                                 service: Annotated[SecurityService, Depends(get_security_service)]) -> schemas.Token:
    """
    login for OAuth2 username & password (& scopes)
    """
    user = await service.authenticate_user(form_data.username, form_data.password)
    if not user:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Incorrect username or password")
    return {"access_token": await service.generate_token_for(user.name, user.role),
            "token_type": "bearer"}


@router.post(REGISTER_URL)
async def register(service: Annotated[UserService, Depends(get_user_service)],
                   user_data: schemas.UserCreation):
    await service.create_user(user=user_data)
    return Response(status_code=status.HTTP_201_CREATED)
