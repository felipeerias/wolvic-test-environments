# wolvic-test-environments

Test environments for the Wolvic Web browser for VR.

## Procedure

To get started, you will need a set of 6 PNG images forming a cubemap.

If instead of a cubemap you have one large panorama image, you can convert it with this tool:https://jaxry.github.io/panorama-to-cubemap/

The source files must have the following names: `negx.png`, `negy.png`, `negz.png`, `posx.png`, `posy.png`, `posz.png`.


```shell
# Define the environment's id
ENVNAME=myenvironment

# Clean up
rm *.ktx *_srgb.png *.zip

# Resize and zip the original PNG images
mogrify -resize 1024x1024! *.png
zip ${ENVNAME}_misc.zip *.png 

# KTX textures
for f in *.png; do mipgen -f ktx -m 1 -c etc_rgb8_rgba_100 --strip-alpha "$f" "$(basename "${f%.*}").ktx"; done
zip "${ENVNAME}.zip" *.ktx

# KTX textures in sRGB color format
for f in *.png; do mipgen -f ktx -m 1 -c etc_srgb8_rgba_100 --strip-alpha "$f" "$(basename "${f%.*}")_srgb.ktx"; done
zip ${ENVNAME}_ktx_srgb.zip *_srgb.ktx

# PNG images in sRGB color format
for file in *.png; do convert "$file" -colorspace sRGB "${file%.png}_srgb.png"; done
zip ${ENVNAME}_misc_srgb.zip *_srgb.png

# Thumbnail
convert posx.png -resize 512x512 -gravity Center -crop 256x256+0+0 ${ENVNAME}.png

# Copy to a new folder in this project
mkdir ../wolvic-test-environments/${ENVNAME}
cp ${ENVNAME}.png *.zip ../wolvic-test-environments/${ENVNAME}

# Finally, remember to update props.json
```

## Environments

- `winterforest`: Winter Forest by MozillaHubs at Sketchfab (CC BY-NC-SA)
- `bcnrooftop`: Barcelona Rooftops by MozillaHubs at Sketchfab (CC BY-NC-SA)
- `malibuoverlook`: Malibu Overlook by MozillaHubs at Sketchfab (CC BY-NC-SA)
- `monumentvalley`: Monument Valley Lookout by MozillaHubs at Sketchfab (CC BY-NC-SA)
- `milkyway`: "Milkyway by MozillaHubs at Sketchfab (CC BY-NC-SA)
- `basicsky`: "Basic Sky by Paul at Sketchfab (CC BY)
- `animesky`: "Anime Sky by Paul at Sketchfab (CC BY)
- `abovetheclouds`: Above The Clouds by Paul at Sketchfab (CC BY)
- `autumnforest`: Autumn Forest by Paul at Sketchfab (CC BY)
- `snowycabin`: Snowy Cabin by Paul at Sketchfab (CC BY)
- `futuristiccity`: Roftops Futuristic City by Paul at Sketchfab (CC BY)
- `fairytalegarden`: Fairytale_Garden by Giimann at Sketchfab (CC BY)
- `fantasylandscape3`: Fantasy Landscape 3 by Giimann at Sketchfab (CC BY)
- `nightforest`: Night Forest With Aurora Sky by Architecture_Interior at Sketchfab (CC BY)
- `lowpolyroom`: Stylized Room by Van_Twinkle at Sketchfab (CC BY)

## Testing

To test these environments on Wolvic 1.5.1, replace the value of the build variable `PROPS_ENDPOINT` with `"https://darker.ink/wolvic-test-environments/props.json"` and recompile.

