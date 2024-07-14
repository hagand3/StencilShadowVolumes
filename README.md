This project is a demo of shadow volumes facilitated by GameMaker's 2024.6 update giving access to stencil buffer functionality. The demo showcases simple cubes as shadowcasters and multiple light sources using GameMaker's built-in lighting functions.

**Shadow Volumes**
Shadow volumes are separate vertex buffers derived from shadowcasting geometry. Shadow Volumes are constructed by analyzing the shadowcasting geometry for possible silhouette edges. A silhouette edge in this case is an edge shared by two triangles whereby it's _possible_ for one triangle to be facing a light source while the other does not. For each silhouette edge found, a quad is written to the shadow volume buffer. This quad has vertices V1_na, V2_na, V2_nb, and V1_nb, where V1 and V2 denote the two vertices forming this edge and na and nb denote the normals of triangles a and b which share this edge. Now we have possible silhouette edges, we need to determine whether or not it actually is a silhouette edge. We offload this work to the GPU so we can do this at run-time. If triangle a is facing the light and triangle b is not, the vertices containing normals from triangle b will be extruded away from the light source while the vertices containing normals from triangle a will remain stationary. This "reveals" the quad, which otherwise has zero area. As long as the winding direction of the shadowcasting geometry is consistently defined, the extruded quads will be consistently front-facing or back-facing quads. The rendering pipeline relies on drawing shadow volumes in two phases: once with back-facing shadow volume quads culled, and once with front-facing shadow volume quads culled. The stencil buffer is employed by incrementing or decrementing for each fragment of the shadow volume that passes (or fails) the depth test. The actual sequence of events is better described in numerous online resources which I'll list at the bottom for further reading. 

**Z-pass and Z-fail**
There are two popular techniques for rendering shadow volumes: Z-pass (or depth-pass) and Z-fail (or depth-fail). Z-pass requires less shadow volume geometry but limits you to scenes where the camera cannot intersect a volume, otherwise the stencil buffer will miscount and the shadows will appear to invert. Z-fail requires more geometry (light and dark caps) but allows for cameras inside shadow volumes. Z-pass can be a good choice for games with a top-down perspective and light sources guaranteed to be above the geometry, that is, the shadow volumes will never point towards the camera. Z-fail can be a good choice for a first-person perspective where the camera is likely to be inside a shadow volume at some point.

**Light and Dark Caps (Z-fail only)**
Light and Dark caps are shadow volume geometry which face towards and away from a light source. The light cap is required to prevent artifacts at the shadowcasting object's light-facing surfaces. The dark cap is required to ensure a closed shadow volume when it extends away from the camera, without which would result in a hole. Dark caps may not be required if an infinitely far source is assumed, whereby extruded vertices all converge at the same point some large distance away. Light and dark caps are generated by simply duplicating the original shadowcasting geometry in the shadow volume. The best depiction of this can be seen here: https://cglearn.eu/images/course/shadows/shadowVolume2.png (from the article found here: https://cglearn.eu/pub/computer-graphics/shadows). In this way, we can use the exact same shader instructions described above. Triangles from the light cap will remain stationary while triangles from the dark cap will be extruded away from the light source, stretching the silhouette edge quads along with them.

**Resources**
The process of rendering shadow volumes is an involved topic with lots of good articles floating around. Here's a non-exhaustive list of links for some ones I found helpful:
- https://cglearn.eu/pub/computer-graphics/shadows
- https://en.wikipedia.org/wiki/Shadow_volume
- https://developer.nvidia.com/gpugems/gpugems/part-ii-lighting-and-shadows/chapter-9-efficient-shadow-volume-rendering
- https://developer.nvidia.com/gpugems/gpugems3/part-ii-light-and-shadows/chapter-11-efficient-and-robust-shadow-volumes-using
- https://ogldev.org/www/tutorial40/tutorial40.html
- https://www.gamedev.net/reference/articles/article1873.asp 
- https://aras-p.info/texts/revext.html
- https://www.jankautz.com/courses/ShadowCourse/08-SoftShadowVolumes.pdf
- https://fileadmin.cs.lth.se/graphics/research/shadows/ulf_thesis_lores.pdf
