rm -rf static index.html
npm run build
cp -r project-tools/dist .
mv dist/* .
rm -rf dist
sed -i -e 's|/static|/tools/static|g' index.html
git add .
git commit -m "new build"
git push