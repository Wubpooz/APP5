import bcrypt


def verify_password(plain_password: str | bytes, hashed_password: str | bytes) -> bool:
    """
    check that a password match its hash counterpart
    :param plain_password: the password to check
    :param hashed_password: the hash to check the password against
    :return: a boolean representing if the password is equal to the hash
    """
    if isinstance(hashed_password, str):
        hashed_password = hashed_password.encode()
    if isinstance(plain_password, str):
        plain_password = plain_password.encode()
    return bcrypt.checkpw(plain_password, hashed_password)


def get_password_hash(password: str | bytes) -> str:
    """
    get the hash of a password
    :param password: the password to hash
    :return: the hash of the password
    """
    if isinstance(password, str):
        password = password.encode()
    return bcrypt.hashpw(password, bcrypt.gensalt()).decode()
