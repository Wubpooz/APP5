echo "destroying previous build env"
rm -rf build
mkdir build
echo "Building Frontend"
cd frontend/AwefullPizzaShop || exit 1
ng build
mv dist ../../build
cd ../../
echo "Building Backend"
cd backend || exit 1
docker build -t awefull-pizza-shop-backend . || ( echo "build failed" && exit 1 )
echo "Building nginx docker"
cd ..
cp nginx.conf build/
openssl req -x509 -newkey rsa:4096 -keyout build/app1.tiweb.tp.ubik.academy.key -out build/app1.tiweb.tp.ubik.academy.crt -sha256 -days 3650 -nodes -subj "/C=XX/ST=StateName/L=CityName/O=CompanyName/OU=CompanySectionName/CN=CommonNameOrHostname"
docker build -t awefull-pizza-shop-frontend . || ( echo "build failed" && exit 1 )
echo "Building XSS poller"
docker build -t awefull-pizza-shop-xss-poller -f Dockerfile-XSS-poller . || ( echo "build failed" && exit 1 )