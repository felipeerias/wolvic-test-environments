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
| ![](winterforest/winterforest.png) | `winterforest` | [_Winter Forest_](https://sketchfab.com/3d-models/sky-pano-winter-forest-b42c27358ab04e8885ffb2ecf69c352c) | **MozillaHubs** at Sketchfab | CC BY-NC-SA |
| ![](bcnrooftop/bcnrooftop.png) | `bcnrooftop` | [_Barcelona Rooftops_](https://sketchfab.com/3d-models/sky-pano-barcelona-rooftops-0f836cdac86441ec93593620c71ec3d6) | **MozillaHubs** at Sketchfab | CC BY-NC-SA |
| ![](malibuoverlook/malibuoverlook.png) | `malibuoverlook` | [_Malibu Overlook_](https://sketchfab.com/3d-models/sky-pano-malibu-overlook-8ef3cf8d717d4598a661e41fc2a7097f) | **MozillaHubs** at Sketchfab | CC BY-NC-SA |
| ![](monumentvalley/monumentvalley.png) | `monumentvalley` | [_Monument Valley Lookout_](https://sketchfab.com/3d-models/sky-pano-monument-valley-lookout-b9ead322f9bd40ec8eb6a2d33908e592) | **MozillaHubs** at Sketchfab | CC BY-NC-SA |
| ![](milkyway/milkyway.png) | `milkyway` | [_Milkyway_](https://sketchfab.com/3d-models/sky-pano-milkyway-0016725c047a4ea18cd0b5e5ef2fe441) | **MozillaHubs** at Sketchfab | CC BY-NC-SA |
| ![](basicsky/basicsky.png) | `basicsky` | [_Basic Sky_](https://sketchfab.com/3d-models/free-skybox-basic-sky-b2a4fd1b92c248abaae31975c9ea79e2) | **Paul** at Sketchfab | CC BY |
| ![](animesky/animesky.png) | `animesky` | [_Anime Sky_](https://sketchfab.com/3d-models/free-skybox-anime-sky-56a60c1d1e8b44eabff138374f996d8f) | **Paul** at Sketchfab | CC BY |
| ![](abovetheclouds/abovetheclouds.png) | `abovetheclouds` | [_Above The Clouds_](https://sketchfab.com/3d-models/free-skybox-above-the-clouds-77e196f5089040ffb7b4d32c6a3fc035) | **Paul** at Sketchfab | CC BY |
| ![](autumnforest/autumnforest.png) | `autumnforest` | [_Autumn Forest_](https://sketchfab.com/3d-models/free-skybox-autumn-forest-3ba29976640c4b26a66d6cea0556b7d6) | **Paul** at Sketchfab | CC BY |
| ![](snowycabin/snowycabin.png) | `snowycabin` | [_Snowy Cabin_](https://sketchfab.com/3d-models/free-skybox-snowy-cabin-c672c14f6aa64af89b1f52d6d1ac8b24) | **Paul** at Sketchfab | CC BY |
| ![](futuristiccity/futuristiccity.png) | `futuristiccity` | [_Rooftops Futuristic City_](https://sketchfab.com/3d-models/free-skybox-rooftops-futuristic-city-9b65d7f199a74f1dadef76a438244502) | **Paul** at Sketchfab | CC BY |
| ![](fairytalegarden/fairytalegarden.png) | `fairytalegarden` | [_Fairytale_Garden_](https://sketchfab.com/3d-models/fairytale-garden-bc4b1df99f764a7384870dd64ed47313) | **Giimann** at Sketchfab | CC BY |
| ![](fantasylandscape3/fantasylandscape3.png) | `fantasylandscape3` | [_Fantasy Landscape 3_](https://sketchfab.com/3d-models/fantasy-landscape-3-ded6e2bb0cfd4ef785b81fed2178c2fd) | **Giimann** at Sketchfab | CC BY |
| ![](lowpolyroom/lowpolyroom.png) | `lowpolyroom` | [_Stylized Room_](https://sketchfab.com/3d-models/skybox-stylized-room-41f386740dbb4de7af2724734f98151f) | **Van_Twinkle** at Sketchfab | CC BY |
| ![](nightforest/nightforest.png) | `nightforest` | [_Night Forest With Aurora Sky_](https://sketchfab.com/3d-models/sky-box-8k-night-forest-scene-with-aurora-sky-a626c2f3eda14177b07f9c345a17df60) | **Architecture_Interior** at Sketchfab | CC BY |

## Testing

To test these environments on Wolvic 1.5.1, replace the value of the build variable `PROPS_ENDPOINT` in `app/build.gradle` with `"https://darker.ink/wolvic-test-environments/props.json"` and recompile.

```
buildConfigField 'String', 'PROPS_ENDPOINT', '"https://darker.ink/wolvic-test-environments/props.json"'
```

