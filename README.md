# wolvic-test-environments

Test environments for the Wolvic Web browser for VR.

## Procedure

To get started, you will need a set of 6 PNG images forming a cubemap.

If instead of a cubemap you have one large panorama image, you can convert it with this tool:https://jaxry.github.io/panorama-to-cubemap/

```shell
# Define the environment's id
ENVNAME=myenvironment

# Clean up
rm *.ktx *_srgb.png *.zip

# Resize and zip the original PNG images
mogrify -resize 1024x1024! *.png
zip ${ENVNAME}_misc.zip *.png 

# KTX textures
for f in *.png; do mipgen -f ktx -m 1 -c etc_rgb8_rgba_100 $f $(basename ${f%.*}).ktx; done
zip ${ENVNAME}.zip *.ktx
cp ${ENVNAME}.zip ${ENVNAME}_ktx.zip

# KTX textures in sRGB color format
for f in *.png; do mipgen -f ktx -m 1 -c etc_srgb8_rgba_100 --strip-alpha $f $(basename ${f%.*})_srgb.ktx; done
zip ${ENVNAME}_ktx_srgb.zip *_srgb.ktx

# PNG images in sRGB color format
for file in *.png; do convert "$file" -colorspace sRGB "${file%.png}_srgb.png"; done
zip ${ENVNAME}_misc_srgb.zip *_srgb.png

# Thumbnail
convert posx.png -resize 512x512 -gravity Center -crop 256x256+0+0 ${ENVNAME}.png

# Copy to a new folder in this project
mkdir ../wolvic-test-environments/${ENVNAME}
cp ${ENVNAME}.png *.zip ../wolvic-test-environments/${ENVNAME}

# Finally, update props.json
```

## Environments

- `abovetheclouds`: Above the clouds by Paul (@paul_paul_paul at Sketchfab), CC Attribution)
- `animesky`: Anime sky by Paul (@paul_paul_paul at Sketchfab), CC Attribution)
- `autumnforest`: Autumn forest by Paul (@paul_paul_paul at Sketchfab), CC Attribution)
- `basicsky`: Basic sky by Paul (@paul_paul_paul at Sketchfab), CC Attribution)
- `futuristiccity`: Futuristic city by Paul (@paul_paul_paul at Sketchfab), CC Attribution)
- `snowycabin`: Snowy cabin by Paul (@paul_paul_paul at Sketchfab), CC Attribution)
