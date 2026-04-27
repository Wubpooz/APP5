from datetime import timedelta, datetime, UTC
from logging import getLogger
from typing import Optional

from fastapi import HTTPException
from fastapi.security import SecurityScopes
from jose import jwt, JWTError
from pydantic import ValidationError
from starlette import status

from awefull_pizza_shop.database import models
from awefull_pizza_shop.database.models.user import UserRole
from awefull_pizza_shop.database.user.service import UserService
from awefull_pizza_shop.webserver import schemas
from awefull_pizza_shop.webserver.config import settings
from awefull_pizza_shop.webserver.security.cryptography import verify_password

USERNAME_SUB_PREFIX = "username:"

logger = getLogger(__name__)

PROTECTION_AGAINST_TIMING_ATTACK = "$2b$12$vf3Xs/xanSeWZE4fu1Z0Xu/nHx0Fiia4RfAjKjpdygdBHXqyUqZU2"


def create_access_token(data: dict, expires_delta: timedelta | None = None) -> str:
    """
    generate a JWT access token using data and configuration settings.
    :param data: the data to include in the JWT token
    :param expires_delta: an optional timedelta for the expiration of the token. if not set the value from the settings
     will be used
    :return: a JWT token
    """
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.now(UTC) + expires_delta
    else:
        expire = datetime.now(UTC) + timedelta(minutes=settings.JWT_ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, settings.JWT_SECRET_KEY, algorithm=settings.JWT_ALGORITHM)
    return encoded_jwt


def parse_jwt_token(token: str) -> Optional[schemas.TokenData]:
    """
    parse a JWT token string and convert it to a schemas.TokenData if it is valid otherwise return None
    :param token: the token to decode
    :return: either a parsed TokenData or None if invalid
    """
    payload = jwt.decode(token, settings.JWT_SECRET_KEY, algorithms=[settings.JWT_ALGORITHM])
    token_scopes = payload.get("scopes", [])
    subject: str = payload.get("sub")
    if subject is None:
        return None
    if subject.startswith(USERNAME_SUB_PREFIX):
        username = subject[len(USERNAME_SUB_PREFIX):]
        if username == "":
            return None
        return schemas.TokenData(username=username, scopes=token_scopes)
    else:
        raise NotImplementedError(subject)


def _validate_scopes(security_scopes: SecurityScopes, scopes: list[str]):
    if security_scopes.scopes:
        authenticate_value = f'Bearer scope="{security_scopes.scope_str}"'
    else:
        authenticate_value = "Bearer"
    for scope in security_scopes.scopes:
        if scope not in scopes:
            logger.debug("invalid scopes %s", scope)
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Not enough permissions",
                headers={"WWW-Authenticate": authenticate_value},
            )


def _get_credentials_exception(security_scopes):
    if security_scopes.scopes:
        authenticate_value = f'Bearer scope="{security_scopes.scope_str}"'
    else:
        authenticate_value = "Bearer"
    return HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": authenticate_value},
    )


class SecurityService:
    def __init__(self, user_service: UserService):
        self.user_service = user_service

    async def get_current_user(self, security_scopes: SecurityScopes, token: str) -> models.User:
        """
        get a user from a jwt token and validate its perms.
        :param security_scopes: the scopes the user must have
        :param token: the jwt token to extract data from
        :return:
        """
        try:
            token_data = parse_jwt_token(token)
            if token_data is None:
                logger.debug("Authentication failed due to token_data being None")
                raise _get_credentials_exception(security_scopes)
        except (JWTError, ValidationError) as e:
            logger.debug("Authentication failed due to Exception %s", e)
            raise _get_credentials_exception(security_scopes)
        user = await self.user_service.take_user_by_username(username=token_data.username)
        if user is None:
            logger.debug("Authentication failed due to user being None")
            raise _get_credentials_exception(security_scopes)
        _validate_scopes(security_scopes, token_data.scopes)
        return user

    async def generate_token_for(self, username: str, role: UserRole):
        """
        validate that a user have requested scopes and generate a token with those scopes
        :param username: the username of the user to get the permission from
        :param scopes: the scopes to check
        :raise ScopeNotAllowed: if user don't have a scope specified in scopes
        :return: a JWT token with given scopes
        """
        return create_access_token({
            "sub": f"{USERNAME_SUB_PREFIX}{username}",
            "role": role.value
        })

    async def authenticate_user(self, username: str, password: str) -> bool | models.User:
        """
        check if a user exist with given username and password.
        :param username: the username of the potential user
        :param password: the password of the potential user
        :return: False if the user don't exist or the password don't match. The user corresponding if it matches.
        """
        user = await self.user_service.take_user_by_username(username)
        if not user:
            verify_password(password, PROTECTION_AGAINST_TIMING_ATTACK)
            return False
        if not verify_password(password, user.hashed_password):
            return False
        return user
