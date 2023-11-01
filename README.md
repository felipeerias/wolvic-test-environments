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

|    | ID | Title | Author | License |
| -- | -- | ----- | ------ | ------- |
| ![](winterforest/winterforest.png) | `winterforest` | _Winter Forest_ | **MozillaHubs** at Sketchfab | CC BY-NC-SA |
| ![](bcnrooftop/bcnrooftop.png) | `bcnrooftop` | _Barcelona Rooftops_ | **MozillaHubs** at Sketchfab | CC BY-NC-SA |
| ![](malibuoverlook/malibuoverlook.png) | `malibuoverlook` | _Malibu Overlook_ | **MozillaHubs** at Sketchfab | CC BY-NC-SA |
| ![](monumentvalley/monumentvalley.png) | `monumentvalley` | _Monument Valley Lookout_ | **MozillaHubs** at Sketchfab | CC BY-NC-SA |
| ![](milkyway/milkyway.png) | `milkyway` | _Milkyway_ | **MozillaHubs** at Sketchfab | CC BY-NC-SA |
| ![](basicsky/basicsky.png) | `basicsky` | _Basic Sky_ | **Paul** at Sketchfab | CC BY |
| ![](animesky/animesky.png) | `animesky` | _Anime Sky_ | **Paul** at Sketchfab | CC BY |
| ![](abovetheclouds/abovetheclouds.png) | `abovetheclouds` | _Above The Clouds_ | **Paul** at Sketchfab | CC BY |
| ![](autumnforest/autumnforest.png) | `autumnforest` | _Autumn Forest_ | **Paul** at Sketchfab | CC BY |
| ![](snowycabin/snowycabin.png) | `snowycabin` | _Snowy Cabin_ | **Paul** at Sketchfab | CC BY |
| ![](futuristiccity/futuristiccity.png) | `futuristiccity` | _Roftops Futuristic City_ | **Paul** at Sketchfab | CC BY |
| ![](fairytalegarden/fairytalegarden.png) | `fairytalegarden` | _Fairytale_Garden_ | **Giimann** at Sketchfab | CC BY |
| ![](fantasylandscape3/fantasylandscape3.png) | `fantasylandscape3` | _Fantasy Landscape 3_ | **Giimann** at Sketchfab | CC BY |
| ![](nightforest/nightforest.png) | `nightforest` | _Night Forest With Aurora Sky_ | **Architecture_Interior** at Sketchfab | CC BY |
| ![](lowpolyroom/lowpolyroom.png) | `lowpolyroom` | _Stylized Room_ | **Van_Twinkle** at Sketchfab | CC BY |

## Testing

To test these environments on Wolvic 1.5.1, replace the value of the build variable `PROPS_ENDPOINT` in `app/build.gradle` with `"https://darker.ink/wolvic-test-environments/props.json"` and recompile.

```
buildConfigField 'String', 'PROPS_ENDPOINT', '"https://darker.ink/wolvic-test-environments/props.json"'
```

