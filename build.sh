if [ ! -d ./builds ]; then
  mkdir -p ./builds;
fi

echo "Building..."
pdc ./source ./builds/Uprat.pdx
echo "Done"