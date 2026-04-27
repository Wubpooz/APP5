from typing import Annotated

from fastapi import Depends, HTTPException
from fastapi import Request
from fastapi.security import OAuth2PasswordBearer, SecurityScopes
from starlette import status

from awefull_pizza_shop.database import models
from awefull_pizza_shop.database.models.user import UserRole
from awefull_pizza_shop.webserver.dependencies.database_service import get_security_service
from awefull_pizza_shop.webserver.security.service import SecurityService

SCOPES = {}

oauth2_scheme = OAuth2PasswordBearer(
    tokenUrl="token",
    scopes=SCOPES
)


async def get_current_user(security_scopes: SecurityScopes,
                           security_service: Annotated[SecurityService, Depends(get_security_service)],
                           request: Request
                           ) -> models.User:
    return await security_service.get_current_user(security_scopes, (await oauth2_scheme(request)))


async def get_current_active_user(current_user: Annotated[models.User, Depends(get_current_user)]) -> models.User:
    """
    get the current user if it is active
    """
    if current_user.disabled:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Inactive user")
    return current_user


async def validate_user_admin(current_user: Annotated[models.User, Depends(get_current_user)]):
    if current_user.role != UserRole.ADMIN:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="You are not an admin user")
    return current_user
