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
powershell -Command "$cert = New-SelfSignedCertificate -DnsName 'app1.tiweb.tp.ubik.academy' -CertStoreLocation 'cert:\CurrentUser\My' -NotAfter (Get-Date).AddYears(10); Export-Certificate -Cert $cert -FilePath 'build\app1.tiweb.tp.ubik.academy.crt' -Type CERT -Force; $pwd = ConvertTo-SecureString -String 'temp' -Force -AsPlainText; Export-PfxCertificate -Cert $cert -FilePath 'build\app1.tiweb.tp.ubik.academy.pfx' -Password $pwd -Force; certutil -encode 'build\app1.tiweb.tp.ubik.academy.pfx' 'build\app1.tiweb.tp.ubik.academy.key'" || (echo "Certificate generation failed" && exit /b 1)
docker build -t awefull-pizza-shop-frontend . || (echo "build failed" && exit /b 1)
echo "Building XSS poller"
docker build -t awefull-pizza-shop-xss-poller -f Dockerfile-XSS-poller . || (echo "build failed" && exit /b 1)