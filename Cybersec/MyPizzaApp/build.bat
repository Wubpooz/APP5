@echo off
echo "destroying previous build env"
if exist build rmdir /s /q build
mkdir build
echo "Building Frontend"
cd frontend\AwefullPizzaShop || exit /b 1
call ng build
move dist ..\..\build
cd ..\..\
echo "Building Backend"
cd backend || exit /b 1
docker build -t awefull-pizza-shop-backend . || (echo "build failed" && exit /b 1)
echo "Building nginx docker"
cd ..
copy nginx.conf build\
set "OPENSSL_EXE=C:\Program Files\OpenSSL-Win64\bin\openssl.exe"
if not exist "%OPENSSL_EXE%" (
	echo OpenSSL not found at "%OPENSSL_EXE%".
	exit /b 1
)
del /q build\app1.tiweb.tp.ubik.academy.crt build\app1.tiweb.tp.ubik.academy.key 2>nul
"%OPENSSL_EXE%" req -x509 -newkey rsa:4096 -keyout build\app1.tiweb.tp.ubik.academy.key -out build\app1.tiweb.tp.ubik.academy.crt -sha256 -days 3650 -nodes -subj "/C=XX/ST=StateName/L=CityName/O=CompanyName/OU=CompanySectionName/CN=app1.tiweb.tp.ubik.academy" || (echo "Certificate generation failed" && exit /b 1)
"%OPENSSL_EXE%" x509 -in build\app1.tiweb.tp.ubik.academy.crt -noout || (echo "Generated certificate is not valid PEM" && exit /b 1)
"%OPENSSL_EXE%" pkey -in build\app1.tiweb.tp.ubik.academy.key -noout || (echo "Generated private key is not valid PEM" && exit /b 1)
docker build -t awefull-pizza-shop-frontend . || (echo "build failed" && exit /b 1)
echo "Building XSS poller"
docker build -t awefull-pizza-shop-xss-poller -f Dockerfile-XSS-poller . || (echo "build failed" && exit /b 1)