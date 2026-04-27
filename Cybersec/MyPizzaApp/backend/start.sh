#!/bin/bash
alembic upgrade head
python /app/src/awefull_pizza_shop/webserver/app.py